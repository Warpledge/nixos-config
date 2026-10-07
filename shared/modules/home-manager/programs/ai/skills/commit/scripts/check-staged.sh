#!/usr/bin/env bash
# Run `nix flake check` on exactly what is staged, before committing it.
# Builds a throwaway commit object from the index (HEAD, branch and working tree untouched)
# and checks that revision, so a split commit can't leave the repo unbuildable.
set -euo pipefail

repo="$(git rev-parse --show-toplevel)"
cd "$repo"
tree="$(git write-tree)"
rev="$(git commit-tree "$tree" -p HEAD -m "staged-check")"
echo "checking staged tree as $rev"
nix flake check --no-write-lock-file "git+file://$repo?rev=$rev" 2>&1 \
  | grep -v -E '^(evaluating|checking|warning: Git tree)' | tail -5
