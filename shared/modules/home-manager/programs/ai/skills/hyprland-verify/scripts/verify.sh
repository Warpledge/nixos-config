#!/usr/bin/env bash
# Build a host's generated Hyprland Lua config and run Hyprland's own verifier on it.
# Usage: verify.sh [desktop|laptop] [repo-path]
# Works whichever WM the host runs: windowManager is overridden to "hyprland" in memory only.
set -euo pipefail

host="${1:-desktop}"
repo="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
scratch="$(mktemp -d)"

# Every hypr/*.lua file home-manager would write (hyprland.lua plus extraLuaFiles),
# linked next to the Hyprland binary from the same evaluation.
out="$(nix build --no-link --print-out-paths --impure --expr "
  let
    f = builtins.getFlake (toString $repo);
    d = f.nixosConfigurations.$host;
    hc = d._module.specialArgs.hostConfig // { windowManager = \"hyprland\"; };
    e = d.extendModules { specialArgs = { hostConfig = hc; }; };
    hm = e.config.home-manager.users.\${hc.username};
    files = builtins.filter (n: builtins.match \"hypr/.*\\\\.lua\" n != null) (builtins.attrNames hm.xdg.configFile);
  in e.pkgs.linkFarm \"hyprland-verify\" (
    map (n: { name = n; path = hm.xdg.configFile.\${n}.source; }) files
    ++ [ { name = \"Hyprland\"; path = \"\${e.pkgs.hyprland}/bin/Hyprland\"; } ]
  )")"

cp -rL "$out/hypr" "$scratch/hypr"
chmod -R u+w "$scratch"
echo "host: $host"
echo "files: $(cd "$scratch" && find hypr -name '*.lua' | sort | tr '\n' ' ')"

result="$(cd "$scratch" && XDG_CONFIG_HOME="$scratch" "$out/Hyprland" --verify-config -c "$scratch/hypr/hyprland.lua" 2>&1 \
  | sed -n '/Config parsing result/,$p' | sed '/^\s*$/d' || true)" # Hyprland exits non-zero on errors; print them first
echo "$result"
echo "scratch: $scratch"

grep -q '^config ok$' <<<"$result"
