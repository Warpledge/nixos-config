#!/usr/bin/env bash
# Validate blocked-channels.nix: no duplicate ids, every entry named, list sorted by
# lowercased name under LC_ALL=C. `--sort` rewrites the list into that order in place.
set -euo pipefail
export LC_ALL=C

repo="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
nix="$repo/shared/modules/home/programs/media/freetube/blocked-channels.nix"
mode="${1:-check}"

entries="$(grep -E '^\s*\(mk "' "$nix")"
# Id breaks ties between channels that share a display name
keyed="$(awk -F'"' '{ print tolower($4) "\t" $2 "\t" $0 }' <<<"$entries")"
sorted="$(sort -t$'\t' -k1,1 -k2,2 <<<"$keyed" | cut -f3-)"

if [ "$mode" = "--sort" ]; then
  tmp="$(mktemp)"
  awk -v list="$sorted" '
    /^\s*\(mk "/ { if (!done) { print list; done = 1 } next }
    { print }' "$nix" >"$tmp"
  cat "$tmp" >"$nix" && rm -f "$tmp"
  echo "sorted $(wc -l <<<"$sorted") entries"
  exit 0
fi

status=0
echo "entries: $(wc -l <<<"$entries")"
dupes="$(awk -F'"' '{ print $2 }' <<<"$entries" | sort | uniq -d)"
[ -n "$dupes" ] && { echo "duplicate ids:"; echo "$dupes"; status=1; }
unnamed="$(awk -F'"' '$4 == "" { print $2 }' <<<"$entries")"
[ -n "$unnamed" ] && { echo "entries without a name:"; echo "$unnamed"; status=1; }
if [ "$entries" != "$sorted" ]; then
  echo "not sorted: run with --sort"
  status=1
fi
[ "$status" = 0 ] && echo "ok"
exit "$status"
