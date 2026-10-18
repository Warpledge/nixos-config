#=====================================================================#
# NIRI WINDOW RULES
#=====================================================================#
{
  config,
  lib,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;

  #--- Rules that need Nix (Stylix colours, the translucent app list), spliced in
  #--- where window-rules.json has {"include": "<name>"}
  included = {
    translucent = [
      #--- Opacity Rules (enables blur to show through)
      # Fallback; the active blur preset (blur-presets.nix) overrides the opacity
      {
        matches = import ./translucent-apps.nix;
        opacity = 0.8;
      }
    ];

    styling = [
      #--------------------------------------------------------------------#
      #-- GLOBAL WINDOW STYLING --#
      #--------------------------------------------------------------------#

      {
        geometry-corner-radius = let
          radius = 12.0;
        in {
          bottom-left = radius;
          bottom-right = radius;
          top-left = radius;
          top-right = radius;
        };
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
      {
        matches = [
          {is-floating = true;}
        ];
        shadow.enable = true;
      }
      {
        matches = [
          {
            is-window-cast-target = true;
          }
        ];
        focus-ring = {
          active.color = colors.base0E; # Mauve
          inactive.color = colors.base00; # Dark base for inactive windows
        };
        border = {
          inactive.color = colors.base00; # Same dark base for border inactive
        };
        shadow = {
          color = "${colors.base00}70"; # Transparent dark shadow
        };
        tab-indicator = {
          active.color = colors.base0E;
          inactive.color = colors.base00;
        };
      }
    ];
  };

  #--- Every other rule lives in window-rules.json, which NixOS Settings' Window
  #--- Rules page edits; its name and note fields are labels for that page
  windowRules =
    lib.concatMap
    (r:
      if r ? include
      then included.${r.include}
      else [(removeAttrs r ["name" "note"])])
    (lib.importJSON ./window-rules.json);
in {
  programs.niri.settings = {
    window-rules = windowRules;
    layer-rules = [
      {
        # DMS's blurred wallpaper copy (blurredWallpaperLayer in dms/settings.json),
        # or linux-wallpaperengine when wallpaper = "engine" replaces it
        matches = [
          {namespace = "^dms:blurwallpaper$";}
          {namespace = "^linux-wallpaperengine$";}
        ];
        place-within-backdrop = true;
      }
      {
        matches = [
          {namespace = "^dms:clipboard$";}
          {namespace = "^dms:notification-popup$";}
          # ClipBoard+ panel, emoji picker and item context menu
          {namespace = "^dms-clipboardPlus-";}
          {namespace = "^dms-selection-menu-";}
        ];
        block-out-from = "screen-capture";
      }
    ];
  };

  #--- For NixOS Settings' Window Rules page: every rule niri gets (machine ones
  #--- too) and the window-rules.json this build used
  xdg.configFile."nixos-settings/niri-window-rules.json".text = builtins.toJSON {
    all = config.programs.niri.settings.window-rules;
    file = lib.importJSON ./window-rules.json;
  };

  #--------------------------------------------------------------------#
  #-- Raw KDL Rules
  #--------------------------------------------------------------------#
  #- For rule options niri-flake doesn't expose yet, appended to the
  #- config.kdl DMS generates (a lines option, so definitions merge)
  xdg.configFile.niri-config-dms.text = lib.mkAfter ''
    window-rule {
        match app-id="^org\\.gnome\\.Resources$"
        open-maximized-to-edges false
    }
  '';
}
