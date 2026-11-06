defmodule PublicSufx.RemoteFileFetcherTest do
  use ExUnit.Case, async: true

  alias PublicSufx.RemoteFileFetcher

  test "rejects a server whose certificate isn't trusted" do
    # A certificate chain whose root isn't in the OS trust store. The defaults
    # don't negotiate on OTP 25, so the handshake would fail for another reason.
    cert_options = [key: {:namedCurve, :secp256r1}, digest: :sha256]

    %{server_config: server_config} =
      :public_key.pkix_test_data(%{
        server_chain: %{root: cert_options, intermediates: [], peer: cert_options},
        client_chain: %{root: cert_options, intermediates: [], peer: cert_options}
      })

    {:ok, listen_socket} = :ssl.listen(0, [active: false, reuseaddr: true] ++ server_config)
    {:ok, {_address, port}} = :ssl.sockname(listen_socket)

    start_supervised!(
      {Task,
       fn ->
         {:ok, socket} = :ssl.transport_accept(listen_socket)
         :ssl.handshake(socket, 5_000)
       end}
    )

    assert {:error, {:error, {:failed_connect, reasons}}} =
             RemoteFileFetcher.fetch_remote_file("https://localhost:#{port}/list.dat")

    assert inspect(reasons) =~ "tls_alert"
  end
end
