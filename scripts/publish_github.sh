#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_USER:=akoita}"
: "${REPO:=defi-risk-copilot}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Please install GitHub CLI: https://cli.github.com/"
  exit 1
fi

git init
git add .
git commit -m "chore: initial commit – DeFi Risk Copilot starter"
gh repo create "${GITHUB_USER}/${REPO}" --private --source . --push
echo "Created and pushed to https://github.com/${GITHUB_USER}/${REPO}"
