#=====================================================================#
# NIRI KEYBINDS
#=====================================================================#
{
  config,
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Niri Keybindings
  #--------------------------------------------------------------------#
  programs.niri.settings.binds = let
    # A spawn bind that still fires while the DMS lock screen is up
    locked = cmd: {
      action.spawn = cmd;
      allow-when-locked = true;
    };
  in {
    #--- Media Player Controls
    "XF86AudioPlay" = locked ["playerctl" "play-pause"];
    "XF86AudioStop" = locked ["playerctl" "pause"];
    "XF86AudioPrev" = locked ["playerctl" "previous"];
    "XF86AudioNext" = locked ["playerctl" "next"];

    #--- Applications
    # Screenshot binds live with the other DMS commands in dms/default.nix
    "Mod+Return".action.spawn = ["kitty"];

    "Mod+Q".action.close-window = {};
    "Mod+S".action.switch-preset-column-width = {};
    "Mod+D".action.expand-column-to-available-width = {};
    "Mod+F".action.maximize-column = {};
    "Mod+Shift+F".action.fullscreen-window = {};
    "Mod+G".action.maximize-window-to-edges = {};
    "Mod+Space".action.toggle-window-floating = {};

    "Mod+Alt+1".action.set-column-width = "33.333%";
    "Mod+Alt+2".action.set-column-width = "50%";
    "Mod+Alt+3".action.set-column-width = "66.667%";

    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Plus".action.set-column-width = "+10%";
    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+Shift+Plus".action.set-window-height = "+10%";

    "Mod+WheelScrollUp".action.focus-column-left = {};
    "Mod+WheelScrollDown".action.focus-column-right = {};
    "Mod+Shift+WheelScrollUp".action.focus-workspace-up = {};
    "Mod+Shift+WheelScrollDown".action.focus-workspace-down = {};

    #--- Focus Window
    "Mod+Left".action.focus-column-left = {};
    "Mod+Right".action.focus-column-right = {};
    "Mod+Up".action.focus-workspace-up = {};
    "Mod+Down".action.focus-workspace-down = {};

    #--- Window Movement
    "Mod+Shift+Left".action.move-column-left = {};
    "Mod+Shift+Right".action.move-column-right = {};
    "Mod+Shift+Up".action.move-column-to-workspace-up = {};
    "Mod+Shift+Down".action.move-column-to-workspace-down = {};

    #--- Monitors
    "Mod+Alt+Left".action.focus-monitor-left = {};
    "Mod+Alt+Right".action.focus-monitor-right = {};
    "Mod+Alt+Shift+Left".action.move-column-to-monitor-left = {};
    "Mod+Alt+Shift+Right".action.move-column-to-monitor-right = {};

    #--- Column Stacking
    # Pull the neighbouring window into this column, or push this one out of it
    "Mod+BracketLeft".action.consume-or-expel-window-left = {};
    "Mod+BracketRight".action.consume-or-expel-window-right = {};
    "Mod+T".action.toggle-column-tabbed-display = {};

    #--- Window Resize
    "Mod+Ctrl+Left".action.set-column-width = "-80";
    "Mod+Ctrl+Right".action.set-column-width = "+80";
    "Mod+Ctrl+Up".action.set-window-height = "-80";
    "Mod+Ctrl+Down".action.set-window-height = "+80";

    "Mod+Tab".action.toggle-overview = {};
    "Mod+C".action.center-column = {};
    "Mod+X".action.switch-preset-window-height = {};
    "Mod+Shift+Z".action.reset-window-height = {};

    #--- Workspace Navigation (Number Keys)
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    #--- Move Window to Workspace (Number Keys)
    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

    #--- Apps
    "Mod+Shift+S".action.spawn = ["steam"];
    "Mod+Shift+D".action.spawn = ["goofcord"];
    "Mod+Shift+H".action.spawn = ["heroic"];
    "Mod+Shift+G" = lib.mkIf hostConfig.gaming.lutris {action.spawn = ["lutris"];};
    "Mod+Shift+Y".action.spawn = ["freetube"];
    "Mod+Z".action.spawn = ["zeditor"];
    "Mod+B".action.spawn = ["zen-beta"];
    "Mod+E".action.spawn = ["nautilus"];
    "Mod+Shift+M".action.spawn = ["spotify"];
    "Ctrl+Alt+Delete".action.spawn = ["resources"];
  };

  #--------------------------------------------------------------------#
  #-- Assertion
  #--------------------------------------------------------------------#
  # A string spawn runs its first word only; arguments go in a list
  assertions = let
    bad = lib.attrNames (lib.filterAttrs (_: b: lib.isString (b.action.spawn or null) && lib.hasInfix " " b.action.spawn) config.programs.niri.settings.binds);
  in [
    {
      assertion = bad == [];
      message = "niri bind(s) ${lib.concatStringsSep ", " bad} pass a spawn command with arguments as a string; use a list, e.g. [\"playerctl\" \"play-pause\"].";
    }
  ];
}
