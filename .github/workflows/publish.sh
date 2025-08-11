#!/bin/bash
set -Eeuo pipefail

# Assume package name == repository name
package="${GITHUB_REPOSITORY#*/}"

git config user.name "$GITHUB_ACTOR"
git config user.email "$GITHUB_ACTOR@users.noreply.github.com"

version=`mix run -e "IO.puts(PublicSufx.Mixfile.project()[:version])"`

if git rev-parse "v$version" >/dev/null 2>&1; then
  echo "NOT TAGGING"
else
  echo "TAGGING"
  git tag "v$version"
  git push --tags
fi

if mix hex.info $package "$version"; then
  echo "NOT PUBLISHING"
else
  echo "PUBLISHING"

  # Assumes HEX_API_KEY is set in GitHub Actions secrets
  # https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions
  mix hex.publish --yes
fi
