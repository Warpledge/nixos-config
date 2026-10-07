#!/usr/bin/env bash
# Build only the Moku package (and the Tsunagu pieces it pulls in), not the whole system.
# On a hash mismatch, prints the derivation and the `got:` hash to paste into default.nix.
set -uo pipefail

repo="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
log="$(mktemp)"

nix build --no-link --print-out-paths --impure -L --expr "
  let
    f = builtins.getFlake (toString $repo);
    d = f.nixosConfigurations.desktop;
    hm = d.config.home-manager.users.\${d._module.specialArgs.hostConfig.username};
  in builtins.head (builtins.filter (p: (p.pname or \"\") == \"moku\") hm.home.packages)" >"$log" 2>&1
status=$?

if [ "$status" = 0 ]; then
  echo "built: $(tail -1 "$log")"
else
  grep -E "hash mismatch in fixed-output derivation|^\s+(specified|got):" "$log" | sed 's/^\s*//'
  grep -E "^error:|replace-fail|can't find file to patch|Hunk #[0-9]+ FAILED" "$log" | head -15
  echo "full log: $log"
fi
exit "$status"
