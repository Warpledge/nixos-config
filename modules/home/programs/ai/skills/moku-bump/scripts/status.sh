#!/usr/bin/env bash
# Show pinned Moku / Tsunagu / Kototoro versions beside upstream's. Read-only.
set -euo pipefail

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
mod="$repo/modules/home/programs/media/moku/default.nix"
token="$HOME/.nixos-config-mcp/github"
auth=()
[ -s "$token" ] && auth=(-H "Authorization: Bearer $(tr -d '[:space:]' <"$token")")

latest() { # owner/repo -> newest release tag, else newest tag
  local r
  r="$(curl -fsS "${auth[@]}" "https://api.github.com/repos/$1/releases/latest" 2>/dev/null | jq -r '.tag_name // empty')" || true
  [ -n "$r" ] || r="$(curl -fsS "${auth[@]}" "https://api.github.com/repos/$1/tags?per_page=1" | jq -r '.[0].name // "?"')"
  echo "$r"
}

pin() { grep -o "github:moku-project/$1/[^\"]*" "$repo/flake.nix" | cut -d/ -f3; }

printf '%-10s pinned %-10s latest %s\n' moku "$(pin Moku)" "$(latest moku-project/Moku)"
printf '%-10s pinned %-10s latest %s\n' tsunagu "$(pin Tsunagu)" "$(latest moku-project/Tsunagu)"

kpin="$(grep -o 'kototoro-parsers/[0-9a-f]\{40\}' "$mod" | cut -d/ -f2)"
kver="$(grep -o 'plugin.jar"; # v[0-9.]*' "$mod" | grep -o 'v[0-9.]*' || echo '?')"
# plugin.jar is built onto the `repo` branch by deploy commits, not master
khead="$(curl -fsS "${auth[@]}" "https://api.github.com/repos/skepsun/kototoro-parsers/commits?sha=repo&path=apk/plugin.jar&per_page=1" | jq -r '.[0].sha // "?"')"
printf '%-10s pinned %s (%s)\n%-10s latest plugin.jar commit %s%s\n' kototoro "${kpin:0:12}" "$kver" "" "${khead:0:12}" \
  "$([ "$kpin" = "$khead" ] && echo ' (same)' || echo ' (newer upstream)')"
