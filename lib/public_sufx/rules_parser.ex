defmodule PublicSufx.RulesParser do
  @moduledoc false

  def parse_rules(line_stream) do
    {_, {icann_rules, private_rules}} =
      Enum.reduce(line_stream, {nil, {%{}, %{}}}, fn line, {current_ruleset, rules_tuple} ->
        trimmed_line = String.trim(line)

        cond do
          String.contains?(trimmed_line, "===BEGIN ICANN DOMAINS===") ->
            {:icann, rules_tuple}

          String.contains?(trimmed_line, "===BEGIN PRIVATE DOMAINS===") ->
            {:private, rules_tuple}

          # skip empty lines and comments
          trimmed_line == "" || trimmed_line =~ ~r"^//.*" ->
            {current_ruleset, rules_tuple}

          true ->
            # "Each line is only read up to the first whitespace"
            rule_str =
              Regex.run(~r|^([^\s]+)|, trimmed_line)
              |> hd()

            rule = parse_rule(rule_str)
            rules_tuple = put_rule(rules_tuple, current_ruleset, rule)

            punycode_rule = parse_rule(punycode_domain(rule_str))

            rules_tuple =
              if punycode_rule != rule do
                put_rule(rules_tuple, current_ruleset, punycode_rule)
              else
                rules_tuple
              end

            {current_ruleset, rules_tuple}
        end
      end)

    %{
      icann: icann_rules,
      private: private_rules
    }
  end

  defp parse_rule("!" <> domain), do: {:exception, domain_labels(domain)}
  defp parse_rule("*." <> domain), do: {:wildcard, domain_labels(domain)}
  defp parse_rule(domain), do: {:domain, domain_labels(domain)}

  defp put_rule({icann_rules, private_rules}, :icann, {rule_type, domain}) do
    icann_rules =
      Map.update(icann_rules, rule_type, [domain], fn domains -> [domain | domains] end)

    {icann_rules, private_rules}
  end

  defp put_rule({icann_rules, private_rules}, :private, {rule_type, domain}) do
    private_rules =
      Map.update(private_rules, rule_type, [domain], fn domains -> [domain | domains] end)

    {icann_rules, private_rules}
  end

  @doc false
  # We can only convert domain's to punycode so do not pass through operators
  def punycode_domain("*" <> rule), do: "*" <> punycode_domain(rule)
  def punycode_domain("!" <> rule), do: "!" <> punycode_domain(rule)

  def punycode_domain(rule) do
    rule
    |> :unicode.characters_to_list()
    |> :idna.encode(uts46: true)
    |> to_string()
  end

  # "A domain or rule can be split into a list of labels using the separator "." (dot)."
  defp domain_labels(domain), do: String.split(domain, ".")
end
