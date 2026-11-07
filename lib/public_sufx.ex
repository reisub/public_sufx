defmodule PublicSufx do
  @moduledoc """
  Implements the publicsuffix algorithm described at https://publicsuffix.org/list/.

  Domains are canonicalized before matching: they are NFKC-normalized and
  lower-cased, the IDNA dot variants (`。`, `．` and `｡`) separate labels like
  `.` does, and a trailing dot is ignored. Domains that start with a dot, are
  longer than 4096 bytes or aren't valid UTF-8 are invalid input.
  """

  import PublicSufx.RulesParser

  @data_file Path.expand("../data/public_suffix_list.dat", __DIR__)
  @external_resource @data_file

  rules_line_stream =
    if Application.compile_env(:public_sufx, :download_data_on_compile, false) do
      @public_suffix_list_url "https://publicsuffix.org/list/public_suffix_list.dat"

      case __MODULE__.RemoteFileFetcher.fetch_remote_file(@public_suffix_list_url) do
        {:ok, data} ->
          # The private domains section is last, so a complete file always contains this marker.
          if not String.contains?(data, "===END PRIVATE DOMAINS===") do
            raise """
            PublicSufx: the fetched data file is incomplete, refusing to compile with it.

            Try again or change `download_data_on_compile` config to `false` to use the cached copy of the rules file.
            """
          end

          IO.puts("PublicSufx: fetched fresh data file for compilation.")
          String.split(data, "\n")

        {:error, error} ->
          raise """
          PublicSufx: failed to fetch fresh data file for compilation:
          #{inspect(error)}

          Try again or change `download_data_on_compile` config to `false` to use the cached copy of the rules file.
          """
      end
    else
      File.stream!(@data_file)
    end

  %{icann: icann_rules, private: private_rules} = rules = parse_rules(rules_line_stream)
  @icann_rules icann_rules
  @private_rules private_rules

  # No rule spans more labels than this, so only that many labels at the end of a domain can match.
  @max_rule_labels max_rule_labels(rules)

  # DNS names are at most 253 characters in ASCII form, which is about 1 KB in UTF-8 at worst.
  @max_domain_bytes 4096

  @on_load :load_public_suffix_list

  @doc false
  @spec load_public_suffix_list() :: :ok
  def load_public_suffix_list do
    for type <- [:domain, :wildcard, :exception] do
      icann = Map.get(@icann_rules, type, []) |> MapSet.new()
      private = Map.get(@private_rules, type, []) |> MapSet.new()
      combined = MapSet.union(icann, private)

      :persistent_term.put({__MODULE__, type}, combined)
    end

    :ok
  end

  @doc """
  Extracts the public suffix from the provided domain based on the publicsuffix.org rules.

  Returns `nil` for invalid input, see the module documentation.

  ## Examples

      iex> public_suffix("foo.bar.com")
      "com"
      iex> public_suffix("foo.github.io")
      "github.io"
      iex> public_suffix("Foo.GitHub.io.")
      "github.io"
  """
  @spec public_suffix(String.t()) :: nil | String.t()
  def public_suffix(domain) when is_binary(domain) do
    domain
    |> normalize()
    |> normalized_public_suffix()
  end

  @doc """
  Returns true if the supplied domain is a public suffix based on the publicsuffix.org rules, false otherwise.

  Returns `false` for invalid input, see the module documentation.

  ## Examples

      iex> public_suffix?("foo.bar.com")
      false
      iex> public_suffix?("com")
      true
      iex> public_suffix?("foo.github.io")
      false
      iex> public_suffix?("github.io")
      true
      iex> public_suffix?("GitHub.io.")
      true
  """
  @spec public_suffix?(String.t()) :: boolean()
  def public_suffix?(domain) when is_binary(domain) do
    normalized = normalize(domain)
    normalized != nil and normalized_public_suffix(normalized) == normalized
  end

  @doc """
  Parses the provided domain and returns the prevailing rule based on the
  publicsuffix.org rules. If no rules match, the prevailing rule is "*",
  unless the input is invalid (see the module documentation), in which case
  the function returns `nil`.

  ## Examples

      iex> prevailing_rule("foo.bar.com")
      "com"
      iex> prevailing_rule("co.uk")
      "co.uk"
      iex> prevailing_rule("foo.ck")
      "*.ck"
      iex> prevailing_rule("foobar.example")
      "*"
      iex> prevailing_rule("foo.github.io")
      "github.io"
  """
  @spec prevailing_rule(String.t()) :: nil | String.t()
  def prevailing_rule(domain) when is_binary(domain) do
    case normalize(domain) do
      nil ->
        nil

      normalized ->
        normalized
        |> labels()
        |> find_prevailing_rule()
        |> case do
          {:exception, rule} -> "!" <> Enum.join(rule, ".")
          {:normal, rule} -> Enum.join(rule, ".")
        end
    end
  end

  # "The domain...must be canonicalized in the normal way for hostnames"
  # Returns nil for input that can't be a valid domain.
  defp normalize(domain) when byte_size(domain) > @max_domain_bytes, do: nil

  defp normalize(domain) do
    domain
    # IDNA (UTS #46) treats these as label separators too
    |> String.replace(["。", "．", "｡"], ".")
    |> :unicode.characters_to_nfkc_binary()
    |> case do
      # Inputs with a leading dot should be treated as a special case.
      # see https://github.com/publicsuffix/list/issues/208
      "." <> _domain -> nil
      # A trailing dot only marks the name as fully qualified
      normalized when is_binary(normalized) -> normalized |> String.downcase() |> String.replace_suffix(".", "")
      # Invalid UTF-8
      _error -> nil
    end
  end

  defp normalized_public_suffix(nil), do: nil

  defp normalized_public_suffix(domain) do
    domain
    |> labels()
    |> extract_labels_using_rules()
    |> case do
      nil -> nil
      labels -> Enum.join(labels, ".")
    end
  end

  # "A domain or rule can be split into a list of labels using the separator "." (dot)."
  defp labels(domain) do
    domain
    |> String.split(".")
    |> Enum.take(-@max_rule_labels)
  end

  defp extract_labels_using_rules(labels) do
    num_labels =
      labels
      |> find_prevailing_rule()
      |> case do
        # "If the prevailing rule is a exception rule, modify it by removing the leftmost label."
        {:exception, labels} -> tl(labels)
        {:normal, labels} -> labels
      end
      |> length()

    if length(labels) >= num_labels do
      take_last_n(labels, num_labels)
    end
  end

  defp find_prevailing_rule(labels) do
    # "If more than one rule matches, the prevailing rule is the one which is an exception rule."
    # "If no rules match, the prevailing rule is "*"."
    find_prevailing_exception_rule(labels) ||
      find_prevailing_domain_rule(labels) ||
      {:normal, ["*"]}
  end

  defp find_prevailing_exception_rule([]), do: nil

  defp find_prevailing_exception_rule([_ | suffix] = domain_labels) do
    if matches_exception_rule?(domain_labels) do
      {:exception, domain_labels}
    else
      find_prevailing_exception_rule(suffix)
    end
  end

  defp find_prevailing_domain_rule([]), do: nil

  defp find_prevailing_domain_rule([_ | suffix] = domain_labels) do
    cond do
      matches_domain_rule?(domain_labels) -> {:normal, domain_labels}
      matches_wildcard_rule?(suffix) -> {:normal, ["*" | suffix]}
      true -> find_prevailing_domain_rule(suffix)
    end
  end

  defp take_last_n(list, n) do
    list
    |> Enum.reverse()
    |> Enum.take(n)
    |> Enum.reverse()
  end

  defp matches_exception_rule?(domain_labels) do
    MapSet.member?(:persistent_term.get({__MODULE__, :exception}), domain_labels)
  end

  defp matches_domain_rule?(domain_labels) do
    MapSet.member?(:persistent_term.get({__MODULE__, :domain}), domain_labels)
  end

  defp matches_wildcard_rule?(domain_labels) do
    MapSet.member?(:persistent_term.get({__MODULE__, :wildcard}), domain_labels)
  end
end
