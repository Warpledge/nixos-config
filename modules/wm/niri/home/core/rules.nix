#=====================================================================#
# NIRI WINDOW RULES
#=====================================================================#
{
  config,
  lib,
  user,
  machine,
  ...
}: let
  sideRail = import ../dms/plugins/side-rail/apps.nix {inherit lib user machine;};

  #--- Rules that need Nix, spliced in where window-rules.json has
  #--- {"include": "<name>"}
  included = {
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

    #--- The Mod+A rail's apps open docked beside it (dms/plugins/side-rail);
    #--- SideRail.qml then sets the height and any width saved for the app
    sideRail =
      map (a: {
        matches = [{app-id = "^${lib.escapeRegex a.appId}$";}];
        open-floating = true;
        default-column-width.fixed = a.width;
        default-floating-position = {
          x = sideRail.geometry.rail + sideRail.geometry.gap;
          y = sideRail.geometry.gap;
          relative-to = "top-left";
        };
      })
      sideRail.apps;
  };

  #--- Every other rule is window-rules.json's, with the user's windowRules
  #--- changes; id, name, note and category are labels for Omni Settings
  labelled = import ./window-rules.nix {inherit lib user;};
  labels = ["id" "name" "note" "category" "enable" "translucent"];

  #--- A rule marked translucent gets an opacity rule of its own after it, so the
  #--- Quick Capture exclude doesn't reach the rule's other properties. Fallback
  #--- opacity: the active blur preset (blur-presets.nix) overrides it
  opacityRule = r: {
    inherit (r) matches;
    # DMS's Quick Capture stays opaque (also excluded in blur-presets.nix)
    excludes = [
      {
        app-id = "^dev\\.duxlabs\\.shell$";
        title = "^Quick Capture$";
      }
    ];
    opacity = 0.8;
  };

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
      else let
        rule = floats (removeAttrs r labels);
        # A rule that only marks windows translucent sets nothing else
        bare = removeAttrs rule ["matches" "excludes"] == {};
      in
        lib.optional (!(r.translucent or false && bare)) rule
        ++ lib.optional (r.translucent or false) (opacityRule r))
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
