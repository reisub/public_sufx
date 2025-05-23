defmodule PublicSufx.Mixfile do
  use Mix.Project

  @version "0.6.0"
  @source_url "https://github.com/reisub/public_sufx"

  def project do
    [
      app: :public_sufx,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [
        :logger,
        :inets,
        :ssl
      ]
    ]
  end

  defp deps do
    [
      {:idna, "~> 6.1"},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.22.0", only: [:dev, :test]}
    ]
  end

  defp aliases, do: []

  defp description do
    """
    Operate on domain names using the public suffix rules provided by https://publicsuffix.org/.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/public_sufx/changelog.html",
        "Public Suffix List" => "https://publicsuffix.org/"
      },
      files: [
        "lib/public_sufx",
        "lib/public_sufx.ex",
        "data/public_suffix_list.dat",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
