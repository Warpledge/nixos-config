#=====================================================================#
# NIX-VN - VISUAL NOVEL SUPER-XBR UPSCALE WRAPPER
#=====================================================================#
#- `nix-vn -r 1280x720 %command%` runs the game in gamescope (nix-gamescope)
#- at its own resolution and upscales it to the monitor with Super-xBR
#- (`-F xbr`, patched in nixos/gaming/tools/gamescope). Super+H toggles it.
#- Presets fix the resolution, e.g. `nix-vn-720p %command%`. The vn-setup
#- skill finds a game's resolution and picks one.
{
  lib,
  pkgs,
  ...
}: let
  #--- Preset suffix -> the game's own resolution
  presets = {
    "600p" = "800x600";
    "768p" = "1024x768";
    "720p" = "1280x720";
    "900p" = "1600x900";
    "1080p" = "1920x1080";
  };

  nix-vn =
    pkgs.writeShellScriptBin "nix-vn"
    # bash
    ''
      if [[ $1 != -r || $# -lt 3 ]]; then
        echo "usage: nix-vn -r WIDTHxHEIGHT <command> [args...]" >&2
        exit 1
      fi
      if [[ ! $2 =~ ^([0-9]+)x([0-9]+)$ ]]; then
        echo "nix-vn: resolution must look like 1280x720, got '$2'" >&2
        exit 1
      fi
      w=''${BASH_REMATCH[1]}
      h=''${BASH_REMATCH[2]}
      shift 2

      exec nix-gamescope -w "$w" -h "$h" -F xbr -- "$@"
    '';

  preset = name: res:
    pkgs.writeShellScriptBin "nix-vn-${name}"
    # bash
    ''
      exec ${nix-vn}/bin/nix-vn -r ${res} "$@"
    '';
in {
  home.packages = [nix-vn] ++ lib.mapAttrsToList preset presets;
}
