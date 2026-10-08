#!/usr/bin/env bash
# Stage part of a file, for commits that must not take a whole mixed file.
# Non-interactive stand-in for `git add -p`.
#   hunks.sh list  <file>          number the unstaged hunks of <file>
#   hunks.sh stage <file> 1,3,4    stage only those hunks
# FINE=1 uses zero-context hunks, so changes on neighbouring lines become separate hunks.
# Use the same FINE value for list and stage, since the numbering differs.
set -euo pipefail

cmd="${1:?list|stage}"
file="${2:?file}"
ctx=3 zero=()
[ "${FINE:-0}" = 1 ] && ctx=0 zero=(--unidiff-zero)
diff="$(git diff --no-color -U"$ctx" -- "$file")"
[ -n "$diff" ] || { echo "no unstaged changes in $file"; exit 0; }

case "$cmd" in
list)
  awk '/^@@/ { n++; print "--- hunk " n " " $0; next } n { print }' <<<"$diff"
  ;;
stage)
  want="${3:?hunk numbers, e.g. 1,3}"
  # Keep the file header, then only the selected hunks; git apply recounts nothing,
  # so whole hunks are copied verbatim
  awk -v want=",$want," '
    /^@@/ { n++; keep = index(want, "," n ",") > 0 }
    !n || keep { print }' <<<"$diff" | git apply --cached --whitespace=nowarn "${zero[@]}" -
  echo "staged hunks $want of $file"
  ;;
*)
  echo "usage: hunks.sh list|stage <file> [n,m]" >&2
  exit 2
  ;;
esac
