#!/usr/bin/env bash
# Compile every AppArmor policy a host defines; loads nothing, needs no root.
# Usage: check.sh [desktop|laptop] [repo-path]
set -uo pipefail

host="${1:-desktop}"
repo="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cfg="$repo#nixosConfigurations.$host"

etc="$(nix build --no-link --print-out-paths "$cfg.config.environment.etc.\"apparmor.d\".source")" || exit 1
parser="$(nix build --no-link --print-out-paths "$cfg.pkgs.apparmor-parser")/bin/apparmor_parser"
profiles="$(nix build --no-link --print-out-paths "$cfg.pkgs.apparmor-profiles")/etc/apparmor.d"
policies="$(nix eval --raw "$cfg.config.security.apparmor.policies" --apply 'p: builtins.concatStringsSep " " (builtins.attrNames p)')"

status=0
for p in $policies; do
  # -Q: skip the kernel load, -K: skip the cache
  if out="$("$parser" -Q -K -I "$etc" -I "$profiles" "$etc/$p" 2>&1)"; then
    echo "ok    $p"
  else
    echo "FAIL  $p"
    printf '      %s\n' "${out//$'\n'/$'\n'      }"
    status=1
  fi
done
exit "$status"
