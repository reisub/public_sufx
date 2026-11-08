#!/bin/bash
set -Eeuo pipefail

# Prints the GitHub release notes for a version (default: the one in mix.exs):
# its CHANGELOG.md entry without the heading or, for releases that only update
# the public suffix list and so have no entry, a line saying so.

cd "$(dirname "$0")/../.."
version=${1:-$(.github/workflows/version.sh)}

# Everything between "## [$version]" and the next "## [" heading, skipping
# leading blank lines. $(...) drops the trailing ones.
notes=$(awk -v heading="## [$version]" '
  found && /^## \[/ { exit }
  index($0, heading) == 1 { found = 1; next }
  found && !started && NF == 0 { next }
  found { started = 1; print }
' CHANGELOG.md)

if [[ -n $notes ]]; then
  echo "$notes"
# Releases that only update the list have no entry, but the first release of
# a minor version always does. The patch version is the list's date.
elif [[ $version =~ ^([0-9]+\.[0-9]+)\.([0-9]{4})([0-9]{2})([0-9]{2})$ ]] &&
  grep -qF "## [${BASH_REMATCH[1]}." CHANGELOG.md; then
  echo "- Updated the bundled public suffix list to its ${BASH_REMATCH[2]}-${BASH_REMATCH[3]}-${BASH_REMATCH[4]} version"
else
  echo "CHANGELOG.md has no entry for $version" >&2
  exit 1
fi
