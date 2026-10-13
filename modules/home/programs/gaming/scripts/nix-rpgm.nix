#=====================================================================#
# NIX-RPGM - RPG MAKER UPSCALE WRAPPER
#=====================================================================#
#- `nix-rpgm %command%` (Heroic: `nix-rpgm` in the wrapper field) reads the
#- RPG Maker version from the game's folder and runs it through nix-vn at
#- that version's resolution: XP 640x480, VX / VX Ace 544x416, MV / MZ from
#- package.json, 2000/2003 320x240. `-r WxH` or a preset (`nix-rpgm-480p`)
#- overrides a game that resizes itself; a black screen with sound means its
#- window is bigger than the resolution used. Undetected games start without
#- gamescope and show a notification.
{
  lib,
  pkgs,
  ...
}: let
  #--- Preset suffix -> the game's own resolution
  presets = {
    "240p" = "320x240";
    "416p" = "544x416";
    "480p" = "640x480";
    "624p" = "816x624";
    "720p" = "1280x720";
    "768p" = "1024x768";
  };

  jq = "${pkgs.jq}/bin/jq";
  notify = "${pkgs.libnotify}/bin/notify-send";
  nix-rpgm =
    pkgs.writeShellScriptBin "nix-rpgm"
    # bash
    ''
      res=""
      if [[ $1 == -r ]]; then
        res=$2
        shift 2
      fi
      if [[ $# -eq 0 ]]; then
        echo "usage: nix-rpgm [-r WIDTHxHEIGHT] <command> [args...]" >&2
        exit 1
      fi

      # The game folder: the last existing .exe in the command, else the cwd
      dir=$PWD
      for arg in "$@"; do
        if [[ ''${arg,,} == *.exe && -f $arg ]]; then
          dir=$(dirname -- "$arg")
        fi
      done

      detect() {
        local d=$1 p r ini lib
        # MV / MZ (NW.js) take the window size from package.json
        for p in "$d/package.json" "$d/www/package.json"; do
          if [[ -f $p ]]; then
            r=$(${jq} -r '.window | select(.width and .height)
              | "\(.width)x\(.height)"' "$p" 2>/dev/null)
            if [[ -n $r ]]; then
              echo "$r"
              return
            fi
          fi
        done
        # XP / VX / VX Ace name their RGSS runtime in Game.ini
        ini=$(find "$d" -maxdepth 1 -iname game.ini -print -quit)
        if [[ -n $ini ]]; then
          lib=$(grep -a -i -m1 '^Library=' "$ini" | tr -d '\r')
          case ''${lib,,} in
            *rgss1*) echo 640x480 && return ;;
            *rgss2* | *rgss3*) echo 544x416 && return ;;
          esac
        fi
        # 2000/2003
        if [[ -n $(find "$d" -maxdepth 1 -iname 'rpg_rt.*' -print -quit) ]]; then
          echo 320x240
        fi
      }

      [[ -z $res ]] && res=$(detect "$dir" | head -1)
      if [[ -z $res ]]; then
        ${notify} --app-name=nix-rpgm "nix-rpgm" \
          "No RPG Maker version found in $dir; starting without upscaling"
        exec "$@"
      fi

      exec nix-vn -r "$res" "$@"
    '';

  preset = name: res:
    pkgs.writeShellScriptBin "nix-rpgm-${name}"
    # bash
    ''
      exec ${nix-rpgm}/bin/nix-rpgm -r ${res} "$@"
    '';
in {
  home.packages = [nix-rpgm] ++ lib.mapAttrsToList preset presets;
}
