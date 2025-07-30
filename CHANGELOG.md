# Changelog
All notable changes to this project will be documented in this file.

Releases that update only the public suffix list won't be listed in the changelog.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
