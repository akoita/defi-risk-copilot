#!/usr/bin/env bash
set -euo pipefail
: "${GITHUB_USER:=akoita}"
: "${REPO:=defi-risk-copilot}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Please install GitHub CLI: https://cli.github.com/"
  exit 1
fi

REPO_HTTP="https://github.com/${GITHUB_USER}/${REPO}.git"

# Ensure git repo exists
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init
fi

# Make an initial commit only if there are staged changes or untracked files
git add .
if ! git diff --cached --quiet >/dev/null 2>&1; then
  git commit -m "chore: initial commit – DeFi Risk Copilot starter" || true
fi

# Ensure we are on a named branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
if [ "$BRANCH" = "HEAD" ] || [ -z "$BRANCH" ]; then
  BRANCH=main
  git branch -M "$BRANCH"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "Remote 'origin' already set. Pushing to origin/$BRANCH ..."
  git push -u origin "$BRANCH"
  echo "Pushed to existing remote: $(git remote get-url origin)"
  exit 0
fi

# If repo exists on GitHub, add as remote and push; otherwise create it
if gh repo view "${GITHUB_USER}/${REPO}" >/dev/null 2>&1; then
  echo "Repo exists on GitHub. Adding remote and pushing..."
  git remote add origin "$REPO_HTTP" || true
  git push -u origin "$BRANCH"
  echo "Pushed to $REPO_HTTP"
else
  echo "Repo not found on GitHub. Creating and pushing..."
  gh repo create "${GITHUB_USER}/${REPO}" --private --source . --push
  echo "Created and pushed to https://github.com/${GITHUB_USER}/${REPO}"
fi
