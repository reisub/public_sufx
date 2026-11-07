defmodule PublicSufx.RemoteFileFetcher do
  @moduledoc false

  def fetch_remote_file(url) do
    # These are not listed in `applications` in `mix.exs` because
    # this is only used at compile time or in one-off mix tasks --
    # so at deployed runtime, this is not used and these applications
    # are not needed.
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    http_options = [
      connect_timeout: 15_000,
      timeout: 60_000,
      # Before OTP 26, httpc doesn't verify the server's certificate unless told to.
      ssl: [
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    case :httpc.request(:get, {to_charlist(url), []}, http_options, body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} -> {:ok, body}
      otherwise -> {:error, otherwise}
    end
  end
end
