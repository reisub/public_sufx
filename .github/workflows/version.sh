#!/bin/bash
set -Eeuo pipefail

# Prints the package version the way mix.exs computes it, without running
# Elixir, so workflows that hold credentials don't need to compile anything.
# The lint job in ci.yml checks that both stay in sync.

cd "$(dirname "$0")/../.."

minor=$(sed -n 's/^  @minor_version "\(.*\)"$/\1/p' mix.exs)
date=$(sed -n 's|^// VERSION: \([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)_.*|\1\2\3|p' data/public_suffix_list.dat | head -n 1)

if [[ -z $minor || -z $date ]]; then
  echo "version extraction failed" >&2
  exit 1
fi

echo "$minor.$date"
