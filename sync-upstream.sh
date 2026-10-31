#!/usr/bin/env bash
set -euo pipefail

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "error: no 'upstream' remote configured" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree has uncommitted changes; commit or stash them first" >&2
  exit 1
fi

if [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
  echo "error: a rebase is already in progress" >&2
  exit 1
fi

echo "==> Fetching upstream"
git fetch upstream

echo "==> Fast-forwarding main"
git checkout main
if ! git merge --ff-only upstream/main; then
  echo "error: main cannot fast-forward to upstream/main; resolve manually" >&2
  exit 1
fi

echo "==> Pushing main to origin"
git push origin main

echo "==> Checking out custom"
git checkout custom

echo "==> Rebasing custom onto main"
if ! git rebase main; then
  echo "error: rebase stopped due to conflicts. Conflicting files:" >&2
  git diff --name-only --diff-filter=U >&2
  echo "Resolve them and run 'git rebase --continue', or run 'git rebase --abort'." >&2
  exit 1
fi

echo "==> Done. custom is rebased onto main."
echo "    If custom is already pushed, force-pushing requires 'git push --force-with-lease' and your confirmation."
