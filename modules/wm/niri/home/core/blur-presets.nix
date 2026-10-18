#=====================================================================#
# NIRI BLUR PRESETS
#=====================================================================#
# Mod+T cycles these. The chosen one is copied to blur-preset.kdl, which
# dms/wpblur.kdl includes; niri reloads it live.
{
  config,
  lib,
  pkgs,
  ...
}: let
  presetFile = "${config.xdg.configHome}/niri/dms/blur-preset.kdl";

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

      window-rule {
          exclude app-id="^steam$"
          background-effect {
              blur ${lib.boolToString (p.blur != null)}
              xray true
          }
      }
    '';

  # No argument: switch to the next preset. --refresh: re-copy the current one
  blurPreset = pkgs.writeShellApplication {
    name = "niri-blur-preset";
    runtimeInputs = [pkgs.coreutils pkgs.gnused pkgs.libnotify];
    text = ''
      f="${presetFile}"
      names=(${lib.concatMapStringsSep " " (p: p.name) presets})
      files=(${lib.concatMapStringsSep " " (p: "${mkPreset p}") presets})

      current=$(sed -n '1s|^// preset: ||p' "$f" 2>/dev/null || true)
      i=2 # Clear, until Mod+T picks another
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

      if [[ ''${1:-} != --refresh ]]; then
        # Silent, and transient so it stays out of the DMS notification history
        notify-send -a Niri -t 2000 -e -h boolean:suppress-sound:true \
          "Blur preset" "''${names[i]} ($((i + 1))/''${#names[@]})"
      fi
    '';
  };
in {
  home.packages = [blurPreset];

  # Before linkGeneration, so the file exists when niri reloads the new wpblur.kdl
  home.activation.niriBlurPreset = lib.hm.dag.entryBetween ["linkGeneration"] ["writeBoundary"] ''
    run ${lib.getExe blurPreset} --refresh
  '';
}
