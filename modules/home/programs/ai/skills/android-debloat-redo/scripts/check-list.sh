#!/usr/bin/env bash
# Pre-flight for the tablet debloat: refuse the removal list if it names any package the
# note's "Never remove these" table lists, or one that breaks the suffix rule.
# Reads both from the note itself, so the check follows it when the note changes.
set -euo pipefail

repo="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
dir="$repo/docs/android/debloat/Lenovo-Idea-Tab-Pro"
list="$dir/removal-list.txt"

# Backticked package names in the table rows of the "Never remove these" section
# shellcheck disable=SC2016 # the backticks are literal, not expansions
never="$(awk '/^## Never remove these/{f=1; next} /^## /{f=0} f && /^\|/' "$dir/index.md" \
  | grep -o '`[a-z][a-zA-Z0-9_.]*`' | tr -d '`' | sort -u)"

packages="$(grep -v -E '^\s*(#|$)' "$list")"
status=0

echo "removal list: $(wc -l <<<"$packages") packages, never-remove table: $(wc -l <<<"$never") packages"

hits="$(grep -Fx -f <(echo "$never") <<<"$packages" || true)"
[ -n "$hits" ] && { echo "NEVER-REMOVE packages in the list:"; echo "$hits"; status=1; }

suffix="$(grep -E '(\.resources|\.resources\.overlay|controller)$' <<<"$packages" || true)"
[ -n "$suffix" ] && { echo "breaks the suffix rule (.resources, .resources.overlay, controller):"; echo "$suffix"; status=1; }

dupes="$(sort <<<"$packages" | uniq -d)"
[ -n "$dupes" ] && { echo "duplicates:"; echo "$dupes"; status=1; }

[ "$status" = 0 ] && echo "ok"
exit "$status"
