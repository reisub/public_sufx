defmodule PublicSufx.RemoteFileFetcher do
  @moduledoc false

  def fetch_remote_file(url) do
    # These are not listed in `applications` in `mix.exs` because
    # this is only used at compile time or in one-off mix tasks --
    # so at deployed runtime, this is not used and these applications
    # are not needed.
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    url
    |> to_charlist()
    |> :httpc.request()
    |> case do
      {:ok, {{_, 200, _}, _headers, body}} -> {:ok, :erlang.iolist_to_binary(body)}
      otherwise -> {:error, otherwise}
    end
  end
end
