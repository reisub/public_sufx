#!/bin/bash
set -Eeuo pipefail

function check_pr {
  gh pr list --state open --label "outdated check"
}

git config user.name "$GITHUB_ACTOR"
git config user.email "$GITHUB_ACTOR@users.noreply.github.com"
git checkout outdated || git checkout -b outdated

current_version=`mix run -e "IO.puts(PublicSufx.Mixfile.project()[:version])"`

mix public_sufx.sync_files

new_version=`mix run -e "IO.puts(PublicSufx.Mixfile.project()[:version])"`

if [ "$new_version" != "$current_version" ]; then
  git add .
  git commit -m "Update public suffix list"
  git push --force --set-upstream origin outdated

  if [[ $(check_pr) == "" ]]; then
    gh pr create --fill --label "outdated check"
  fi
fi
