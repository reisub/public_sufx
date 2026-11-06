defmodule Mix.Tasks.PublicSufx.SyncFiles do
  @shortdoc "Syncs the files from publicsuffix.org"
  @moduledoc false

  use Mix.Task

  # The outdated workflow runs the script directly, so it doesn't need Elixir.
  @script Path.expand("../../.github/workflows/sync_files.sh", __DIR__)

  def run(_) do
    case System.cmd(@script, [], into: IO.stream(), stderr_to_stdout: true) do
      {_, 0} -> :ok
      {_, status} -> Mix.raise("#{@script} failed with exit status #{status}")
    end
  end
end
