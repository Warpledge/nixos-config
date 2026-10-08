#!/usr/bin/env bash
# Diff a freshly built toplevel against the running system and say whether it needs `nixm boot`. Read-only.
set -euo pipefail

new="${1:?usage: diff.sh <new toplevel store path>}"
out="$(nvd --color never diff /run/current-system "$new")"

# Version changes only ([U] upgrades, [D] downgrades), not the added/removed noise
echo "$out" | grep -E '^\[[UD]' || echo "no version changes"
echo "$out" | grep -E '^Closure size' || true

# Live switches froze the desktop on a new glibc/systemd (2026-10-03) and a new xwayland-satellite (2026-10-07)
core="$(echo "$out" | awk '/^\[[UD]/ && $3 ~ /^(glibc|systemd|niri|xwayland-satellite)$/ {print $3}' | sort -u | paste -sd, -)"
if [ -n "$core" ]; then
  echo "VERDICT: nixm boot ($core changed)"
else
  echo "VERDICT: nixm rebuild"
fi
