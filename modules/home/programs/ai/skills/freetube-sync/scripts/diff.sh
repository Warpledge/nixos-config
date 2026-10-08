#!/usr/bin/env bash
# Compare FreeTube's live blocklist with blocked-channels.nix. Read-only.
# Prints entries to add as ready-made (mk "UC…" "Name") lines, and the ids
# only the module has.
set -euo pipefail

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
db="$HOME/.config/FreeTube/settings.db"
nix="$repo/modules/home/programs/media/freetube/blocked-channels.nix"

if pgrep -f -- '-freetube-[0-9]' >/dev/null; then
  echo "WARNING: FreeTube is running; settings.db is only current after it exits." >&2
fi

# NeDB append-log: later lines win, so reduce by _id before reading
live="$(jq -rs 'reduce .[] as $x ({}; .[$x._id] = $x.value) | .channelsHidden | fromjson
  | .[] | [.name, (.preferredName // "")] | @tsv' "$db")"
module_ids="$(grep -o '(mk "[^"]*"' "$nix" | cut -d'"' -f2 | sort -u)"

echo "live: $(wc -l <<<"$live")  module: $(wc -l <<<"$module_ids")"

echo "--- add to module:"
while IFS=$'\t' read -r id name; do
  grep -qx -- "$id" <<<"$module_ids" || printf '      (mk "%s" "%s")\n' "$id" "${name//\"/\\\"}"
done <<<"$live"

echo "--- only in module (unblocked in the app, or FreeTube still running):"
cut -f1 <<<"$live" | sort -u | comm -13 - <(echo "$module_ids") || true
