#!/bin/bash
set -Eeuo pipefail

# Downloads the latest public suffix list and its test cases into data/.
# Used by the outdated workflow and by `mix public_sufx.sync_files`.

cd "$(dirname "$0")/../.."

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

# Only replaces the local file if the download succeeded and, when a marker
# is given, contains it.
function sync_file {
  local url=$1 path=$2 marker=${3:-}

  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    --retry 3 --max-time 120 --output "$tmp" "$url"

  if [[ -n $marker ]] && ! grep -q -- "$marker" "$tmp"; then
    echo "Downloaded $url looks incomplete (no \"$marker\"), not updating $path" >&2
    exit 1
  fi

  cat "$tmp" >"$path"
  echo "Synced $url to $path"
}

sync_file https://publicsuffix.org/list/public_suffix_list.dat \
  data/public_suffix_list.dat "===END PRIVATE DOMAINS==="

# The test file has no end marker; CI on the update PR catches a broken one.
sync_file https://raw.githubusercontent.com/publicsuffix/list/main/tests/tests.txt \
  data/tests.txt
