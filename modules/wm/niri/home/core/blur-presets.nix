#=====================================================================#
# NIRI BLUR PRESETS
#=====================================================================#
# Mod+T cycles these. The chosen one is copied to blur-preset.kdl, which
# dms/wpblur.kdl includes; niri reloads it live. Mod+Y (niri-opacity-toggle)
# makes apps without an opacity rule translucent at the preset's opacity.
{
  config,
  lib,
  pkgs,
  ...
}: let
  presetFile = "${config.xdg.configHome}/niri/dms/blur-preset.kdl";
  extraFile = "${config.xdg.configHome}/niri/dms/opacity-extra.kdl";
  extraList = "${config.xdg.stateHome}/niri/translucent-extra";

  #--- Matches of every rule with a translucent opacity, so Mod+Y knows to toggle it
  opacityMatches =
    lib.filter (m: lib.all (k: k == "app-id" || k == "title") (lib.attrNames m))
    (import ./translucent-apps.nix
      ++ lib.concatMap (r: r.matches or [])
      (lib.filter (r: (r.opacity or 1) < 1) (lib.importJSON ./window-rules.json)));
  matchTest = m:
    "{ "
    + lib.concatStringsSep " && " (lib.mapAttrsToList (k: v: let
      var =
        if k == "app-id"
        then "\"$id\""
        else "\"$title\"";
    in "m ${var} ${lib.escapeShellArg v}")
    m)
    + "; } && return 0";

  matchLines =
    lib.concatMapStringsSep "\n" (
      m:
        "    match "
        + lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") m)
    )
    (import ./translucent-apps.nix);

  #--- Presets
  # Without blur, the sharp wallpaper is darkened only by the window's own background
  presets = [
    {
      name = "Subtle";
      blur = {
        passes = 2;
        offset = "2.0";
      };
      opacity = "0.92";
    }
    {
      name = "Default";
      blur = {
        passes = 4;
        offset = "4.0";
      };
      opacity = "0.8";
    }
    {
      name = "Clear";
      blur = null;
      opacity = "0.85";
    }
  ];

  # Steam is excluded from the background effect: it draws its own opaque chrome
  mkPreset = p:
    pkgs.writeText "niri-blur-${lib.toLower p.name}.kdl" ''
      // preset: ${p.name}
      ${lib.optionalString (p.blur != null) ''
        blur {
            passes ${toString p.blur.passes}
            offset ${p.blur.offset}
            noise 0.0
            saturation 1.2
        }
      ''}
      window-rule {
      ${matchLines}
          opacity ${p.opacity}
      }

      // DMS popouts; not their :background click-catchers, which cover the screen
      layer-rule {
          match namespace="^dms:(app-launcher|control-center|dash|omni-settings|plugins:plugin|process-list-popout|slideout)$"
          match namespace="^dms-clipboardPlus-panel-"
          opacity ${p.opacity}
      }

      window-rule {
          exclude app-id="^steam$"
          background-effect {
              blur ${lib.boolToString (p.blur != null)}
              xray true
          }
      }
    '';

  # Mod+Y: an app with an opacity rule gets niri's toggle (Mod+Shift+T); any other
  # app goes on or off the list opacity-extra.kdl is written from. --refresh: rewrite it
  opacityToggle = pkgs.writeShellApplication {
    name = "niri-opacity-toggle";
    runtimeInputs = [config.programs.niri.package pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.jq];
    text = ''
      list="${extraList}"
      out="${extraFile}"

      write() {
        opacity=$(sed -n 's/^ *opacity //p' "${presetFile}" 2>/dev/null | head -n1)
        mkdir -p "$(dirname "$out")"
        {
          echo "// Apps Mod+Y made translucent (niri-opacity-toggle)"
          if [[ -s $list ]]; then
            echo "window-rule {"
            while IFS= read -r a; do
              # Regex-escape the app id, then double the backslashes for KDL
              re=$(printf '%s' "$a" | sed 's/[][\\.*^$+?(){}|]/\\&/g; s/\\/\\\\/g')
              echo "    match app-id=\"^$re\$\""
            done <"$list"
            echo "    opacity ''${opacity:-0.85}"
            echo "}"
          fi
        } >"$out.tmp"
        mv "$out.tmp" "$out"
      }

      if [[ ''${1:-} == --refresh ]]; then
        write
        exit 0
      fi

      # Case-insensitive for a (?i) regex, as niri's matching is
      m() {
        local s=$1 re=$2 r=0
        if [[ $re == "(?i)"* ]]; then
          shopt -s nocasematch
          re=''${re#"(?i)"}
        fi
        [[ $s =~ $re ]] || r=1
        shopt -u nocasematch
        return "$r"
      }
      has_rule() {
        ${lib.concatMapStringsSep "\n  " matchTest opacityMatches}
        return 1
      }

      win=$(niri msg --json focused-window)
      id=$(jq -r '.app_id // empty' <<<"$win")
      title=$(jq -r '.title // empty' <<<"$win")
      [[ -n $id ]] || exit 0

      mkdir -p "$(dirname "$list")"
      touch "$list"
      if grep -qxF -- "$id" "$list"; then
        grep -vxF -- "$id" "$list" >"$list.tmp" || true
        mv "$list.tmp" "$list"
        write
      elif has_rule; then
        niri msg action toggle-window-rule-opacity
      else
        echo "$id" >>"$list"
        write
      fi
    '';
  };

  # No argument: switch to the next preset. --refresh: re-copy the current one
  blurPreset = pkgs.writeShellApplication {
    name = "niri-blur-preset";
    runtimeInputs = [pkgs.coreutils pkgs.gnused pkgs.libnotify opacityToggle];
    text = ''
      f="${presetFile}"
      names=(${lib.concatMapStringsSep " " (p: p.name) presets})
      files=(${lib.concatMapStringsSep " " (p: "${mkPreset p}") presets})

      current=$(sed -n '1s|^// preset: ||p' "$f" 2>/dev/null || true)
      i=1 # Default, until Mod+T picks another
      for k in "''${!names[@]}"; do
        if [[ ''${names[k]} == "$current" ]]; then
          i=$k
          [[ ''${1:-} == --refresh ]] || i=$(((k + 1) % ''${#names[@]}))
        fi
      done

      mkdir -p "$(dirname "$f")"
      cp "''${files[i]}" "$f.tmp"
      chmod 644 "$f.tmp"
      mv "$f.tmp" "$f"
      niri-opacity-toggle --refresh # Mod+Y's apps follow the new opacity

      if [[ ''${1:-} != --refresh ]]; then
        # Silent, and transient so it stays out of the DMS notification history
        notify-send -a Niri -t 2000 -e -h boolean:suppress-sound:true \
          "Blur preset" "''${names[i]} ($((i + 1))/''${#names[@]})"
      fi
    '';
  };
in {
  home.packages = [blurPreset opacityToggle];

  # Before linkGeneration, so the file exists when niri reloads the new wpblur.kdl
  home.activation.niriBlurPreset = lib.hm.dag.entryBetween ["linkGeneration"] ["writeBoundary"] ''
    run ${lib.getExe blurPreset} --refresh
  '';
}
