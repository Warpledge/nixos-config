#=====================================================================#
# NIRI WINDOW RULES
#=====================================================================#
{
  config,
  lib,
  user,
  ...
}: let
  #--- Rules that need Nix (the translucent app list), spliced in
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
      # The cast-target rule's colours: dms/colors.kdl (theme/matugen/niri-colors.kdl)
    ];
  };

  #--- Every other rule is window-rules.json's, with the user's windowRules
  #--- changes; id, name, note and category are labels for Omni Settings
  labelled = import ./window-rules.nix {inherit lib user;};
  labels = ["id" "name" "note" "category" "enable"];

  # niri-flake wants floats; a whole number typed in the settings is an int
  floats = v:
    if lib.isAttrs v
    then
      lib.mapAttrs (k: x:
        if lib.elem k ["proportion" "opacity"] && lib.isInt x
        then x * 1.0
        else floats x)
      v
    else if lib.isList v
    then map floats v
    else v;

  windowRules =
    lib.concatMap
    (r:
      if r ? include
      then included.${r.include}
      else [(floats (removeAttrs r labels))])
    labelled;
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

  #--- For Omni Settings' Window Rules page: every rule niri gets (machine ones
  #--- too), the shared and user rules as built, and the changes applied
  xdg.configFile."omni-settings/niri-window-rules.json".text = builtins.toJSON {
    all = config.programs.niri.settings.window-rules;
    rules = map floats (lib.filter (r: !(r ? include)) labelled);
    overrides = user.windowRules;
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
