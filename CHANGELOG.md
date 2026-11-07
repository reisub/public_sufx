# Changelog
All notable changes to this project will be documented in this file.

Releases that update only the public suffix list won't be listed in the changelog.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `public_suffix?/1` canonicalizes its input like `public_suffix/1` does, so upper-case letters, a trailing dot, IDNA dot variants (`。`, `．`, `｡`) and non-NFC Unicode no longer make a public suffix look like a regular domain
- Matching takes linear time; it used to take quadratic time, so a long input could take seconds
- `download_data_on_compile` verifies the server certificate explicitly (httpc only does by default since OTP 26), times out instead of hanging, and refuses an incomplete download
- Wildcard rules no longer add bogus rules such as `*ck`

### Changed

- OTP 26 is now the minimum supported version
- A trailing dot is ignored: `public_suffix("foo.github.io.")` returns `"github.io"` instead of `""`
- Inputs longer than 4096 bytes or with invalid UTF-8 are invalid: `public_suffix/1` and `prevailing_rule/1` return `nil` and `public_suffix?/1` returns `false`

## [0.7.20260507] - 2026-05-10

### Changed

- Elixir 1.15 is now the minimum supported version

## [0.6.20250722] - 2025-07-30

### Changed

- automated monthly updates for the public suffix list we ship

## [0.6.0] - 2025-04-20

### Changed

- `download_data_on_compile` is now false by default, see [reasons](https://github.com/reisub/public_sufx/issues/1)
- support Elixir 1.14
- upate cached rules list

## [0.5.0] - 2025-04-09

### Changed

- Forked `axelson/publicsuffix-elixir`
- Rewrote parsing and rule storage logic
