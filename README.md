# PublicSuffex

[![CI](https://github.com/reisub/public_suffex/actions/workflows/ci.yml/badge.svg)](https://github.com/reisub/public_suffex/actions/workflows/ci.yml)
[![License](https://img.shields.io/hexpm/l/public_suffex.svg)](https://github.com/reisub/public_suffex/blob/main/LICENSE)
[![Version](https://img.shields.io/hexpm/v/public_suffex.svg)](https://hex.pm/packages/public_suffex)
[![Hex Docs](https://img.shields.io/badge/documentation-gray.svg)](https://hexdocs.pm/public_suffex)

`PublicSuffex` is an Elixir library to operate on domain names using
the public suffix rules provided by https://publicsuffix.org/:

> A "public suffix" is one under which Internet users can (or
> historically could) directly register names. Some examples of public
> suffixes are `.com`, `.co.uk` and `pvt.k12.ma.us`. The Public Suffix List is
> a list of all known public suffixes.

This Elixir library provides a means to get the public suffix from any domain:

```iex
iex(1)> PublicSuffex.public_suffix("mysite.foo.bar.com")
"com"
iex(2)> PublicSuffex.public_suffix("mysite.foo.bar.co.uk")
"co.uk"
```

... and a way to check if a domain is a public suffix:

```iex
iex(1)> PublicSuffex.public_suffix?("mysite.foo.bar.co.uk")
false
iex(2)> PublicSuffex.public_suffix?("co.uk")
true
```

The publicsuffix.org data file contains both official ICANN records
and private records:

> ICANN domains are those delegated by ICANN or part of the IANA root zone database. The authorized registry may express further policies on how they operate the TLD, such as subdivisions within it. Updates to this section can be submitted by anyone, but if they are not an authorized representative of the registry then they will need to back up their claims of error with documentation from the registry's website.
>
> PRIVATE domains are amendments submitted by the domain holder, as an expression of how they operate their domain security policy. Updates to this section are only accepted from authorized representatives of the domain registrant. This is so we can be certain they know what they are getting into.

## Working with Rules

You can also gain access to the prevailing rule for a particular domain:

```iex
iex(1)> PublicSuffex.prevailing_rule("mysite.foo.bar.com")
"com"
iex(2)> PublicSuffex.prevailing_rule("mysite.example")
"*"
```

## Installation

The package can be installed as:

  1. Add public_suffix to your list of dependencies in `mix.exs`:

        def deps do
          [{:public_suffex, "~> 0.5.0"}]
        end

  2. If using Elixir < 1.4, then ensure public_suffix is started before your application:

        def application do
          [applications: [:public_suffex]]
        end

## Configuration

`PublicSuffex` downloads a fresh copy of the public suffix list at compile time.

It's also bundled with a cached copy of the public suffix list from
and can be configured not to download a fresh copy of the list
by adding this in your `config.exs`:

```elixir
config :public_suffex, download_data_on_compile: false
```

There are pros and cons to both approaches; which you choose will depend
on the needs of your project:

* Setting `download_data_on_compile` to `true` will ensure that the
  rules are always up-to-date (as of the time you last compiled) but
  could introduce an instability. While we have tried to implement
  the logic in this library according to the publicsuffix.org spec,
  one can imagine future rule changes not being handled properly by
  the existing logic and manifesting itself in a new bug.
* Setting `download_data_on_compile` to `false` (or not setting it at
  all) ensures stable, consistent behavior. In the context of your
  project, you may want compilation to be deterministic. Compilation
  is also a bit faster when a new copy of the rules is not downloaded.
