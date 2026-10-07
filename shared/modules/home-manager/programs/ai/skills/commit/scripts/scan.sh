#!/usr/bin/env bash
# Pre-commit checks for this public repo: gitleaks over the staged changes, plus reminders
# for files that need a human look. Exit 1 when gitleaks finds anything.
set -uo pipefail

repo="$(git rev-parse --show-toplevel)" || exit 1
cd "$repo" || exit 1

staged="$(git diff --cached --name-only)"
if [ -z "$staged" ]; then
  echo "nothing staged"
  exit 0
fi
echo "staged: $(wc -l <<<"$staged") files"

status=0
log="$(mktemp)"
if gitleaks git --pre-commit --staged --redact --no-banner --verbose . >"$log" 2>&1; then
  echo "gitleaks: no leaks in staged changes"
else
  echo "gitleaks: LEAKS FOUND (secrets redacted):"
  grep -E '^(Finding|RuleID|File|Line):' "$log" | sed 's/^/  /'
  status=1
fi
rm -f "$log"

# Tracked and public, but Claude Code also writes approvals near it
if grep -qx '.claude/settings.json' <<<"$staged"; then
  echo "check: .claude/settings.json is staged; read it for tokens, keys, credentialed URLs or private paths"
fi

# Files that must never be committed, whatever .gitignore says
risky="$(grep -E '(^|/)(\.nixos-config-mcp|\.env|.*\.pem|.*\.key|id_[a-z0-9]+|settings\.local\.json)$' <<<"$staged" || true)"
if [ -n "$risky" ]; then
  echo "STOP: staged files that hold secrets by convention:"
  echo "$risky"
  status=1
fi

exit "$status"
