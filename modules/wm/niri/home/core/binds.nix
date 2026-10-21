#=====================================================================#
# NIRI KEYBINDS
#=====================================================================#
{
  config,
  lib,
  machine,
  user,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Niri Keybindings
  #--------------------------------------------------------------------#
  programs.niri.settings.binds = let
    # The user's defaultApps, for the app binds
    chosen = (import ../../../../../lib/default-apps.nix {inherit lib;}).forUser user;
    # The title is what the Mod+/ cheatsheet (DMS) shows for the bind
    bind = title: action: {
      inherit action;
      hotkey-overlay.title = title;
    };
    # Left out of the cheatsheet
    hidden = action: {
      inherit action;
      hotkey-overlay.hidden = true;
    };
    # A hidden spawn bind that still fires while the DMS lock screen is up
    locked = cmd: {
      action.spawn = cmd;
      allow-when-locked = true;
      hotkey-overlay.hidden = true;
    };
  in {
    #--- Media Player Controls
    "XF86AudioPlay" = locked ["playerctl" "play-pause"];
    "XF86AudioStop" = locked ["playerctl" "pause"];
    "XF86AudioPrev" = locked ["playerctl" "previous"];
    "XF86AudioNext" = locked ["playerctl" "next"];

    #--- Applications
    # Screenshot binds live with the other DMS commands in dms/default.nix
    "Mod+Return" = bind "Terminal" {spawn = chosen.terminal.launch;};

    "Mod+Q" = bind "Close window" {close-window = {};};
    "Mod+S" = bind "Cycle column width" {switch-preset-column-width = {};};
    "Mod+D" = bind "Fill empty space" {expand-column-to-available-width = {};};
    "Mod+F" = bind "Maximize column" {maximize-column = {};};
    "Mod+Shift+F" = bind "Fullscreen" {fullscreen-window = {};};
    "Mod+G" = bind "Maximize to screen edges" {maximize-window-to-edges = {};};
    "Mod+Space" = bind "Float / tile window" {toggle-window-floating = {};};
    "Mod+Shift+Space" =
      bind "Switch focus floating / tiled" {switch-focus-between-floating-and-tiling = {};};
    # Turn the window's opacity rule (rules.nix) off and on
    "Mod+Shift+T" = bind "Window transparency on / off" {toggle-window-rule-opacity = {};};
    # Same, and also works on apps without an opacity rule (blur-presets.nix)
    "Mod+Y" = bind "Transparency on / off, any app" {spawn = "niri-opacity-toggle";};
    # Cycle the blur and translucency presets (blur-presets.nix)
    "Mod+T" = bind "Cycle blur preset" {spawn = "niri-blur-preset";};
    # Takes shortcuts back from an app that inhibits them
    "Mod+Escape" = {
      action.toggle-keyboard-shortcuts-inhibit = {};
      allow-inhibiting = false;
      hotkey-overlay.title = "Take shortcuts back from app";
    };

    "Mod+Alt+1" = bind "Column width 1/3" {set-column-width = "33.333%";};
    "Mod+Alt+2" = bind "Column width 1/2" {set-column-width = "50%";};
    "Mod+Alt+3" = bind "Column width 2/3" {set-column-width = "66.667%";};

    "Mod+Minus" = bind "Narrower column" {set-column-width = "-10%";};
    "Mod+Plus" = bind "Wider column" {set-column-width = "+10%";};
    "Mod+Shift+Minus" = bind "Shorter window" {set-window-height = "-10%";};
    "Mod+Shift+Plus" = bind "Taller window" {set-window-height = "+10%";};

    "Mod+WheelScrollUp" = hidden {focus-column-left = {};};
    "Mod+WheelScrollDown" = hidden {focus-column-right = {};};
    "Mod+Shift+WheelScrollUp" = hidden {focus-workspace-up = {};};
    "Mod+Shift+WheelScrollDown" = hidden {focus-workspace-down = {};};

    #--- Focus Window
    "Mod+Left" = bind "Focus left" {focus-column-left = {};};
    "Mod+Right" = bind "Focus right" {focus-column-right = {};};
    # Walk the windows of a stacked or tabbed column before leaving the workspace
    "Mod+Up" = bind "Focus up / workspace above" {focus-window-or-workspace-up = {};};
    "Mod+Down" =
      bind "Focus down / workspace below" {focus-window-or-workspace-down = {};};

    #--- Window Movement
    "Mod+Shift+Left" = bind "Move left" {move-column-left = {};};
    "Mod+Shift+Right" = bind "Move right" {move-column-right = {};};
    "Mod+Shift+Up" =
      bind "Move up / to workspace above" {move-window-up-or-to-workspace-up = {};};
    "Mod+Shift+Down" =
      bind "Move down / to workspace below" {move-window-down-or-to-workspace-down = {};};

    #--- Monitors
    "Mod+Alt+Left" = bind "Focus monitor left" {focus-monitor-left = {};};
    "Mod+Alt+Right" = bind "Focus monitor right" {focus-monitor-right = {};};
    "Mod+Alt+Shift+Left" = bind "Move to monitor left" {move-column-to-monitor-left = {};};
    "Mod+Alt+Shift+Right" =
      bind "Move to monitor right" {move-column-to-monitor-right = {};};

    #--- Column Stacking
    # Pull the neighbouring window into this column, or push this one out of it
    "Mod+BracketLeft" = bind "Stack / unstack left" {consume-or-expel-window-left = {};};
    "Mod+BracketRight" =
      bind "Stack / unstack right" {consume-or-expel-window-right = {};};
    "Mod+Backslash" = bind "Tabbed column on / off" {toggle-column-tabbed-display = {};};

    #--- Window Resize
    "Mod+Ctrl+Left" = bind "Shrink width" {set-column-width = "-80";};
    "Mod+Ctrl+Right" = bind "Grow width" {set-column-width = "+80";};
    "Mod+Ctrl+Up" = bind "Shrink height" {set-window-height = "-80";};
    "Mod+Ctrl+Down" = bind "Grow height" {set-window-height = "+80";};

    "Mod+Tab" = bind "Overview" {toggle-overview = {};};
    "Mod+H" = bind "Center column" {center-column = {};};
    "Mod+X" = bind "Cycle window height" {switch-preset-window-height = {};};
    "Mod+Shift+Z" = bind "Reset window height" {reset-window-height = {};};

    #--- Workspace Navigation (Number Keys)
    # 2-9 are hidden so the cheatsheet lists the number keys once
    "Mod+1" = bind "Go to workspace 1-9" {focus-workspace = 1;};
    "Mod+2" = hidden {focus-workspace = 2;};
    "Mod+3" = hidden {focus-workspace = 3;};
    "Mod+4" = hidden {focus-workspace = 4;};
    "Mod+5" = hidden {focus-workspace = 5;};
    "Mod+6" = hidden {focus-workspace = 6;};
    "Mod+7" = hidden {focus-workspace = 7;};
    "Mod+8" = hidden {focus-workspace = 8;};
    "Mod+9" = hidden {focus-workspace = 9;};

    #--- Move Window to Workspace (Number Keys)
    "Mod+Shift+1" = bind "Send window to workspace 1-9" {move-column-to-workspace = 1;};
    "Mod+Shift+2" = hidden {move-column-to-workspace = 2;};
    "Mod+Shift+3" = hidden {move-column-to-workspace = 3;};
    "Mod+Shift+4" = hidden {move-column-to-workspace = 4;};
    "Mod+Shift+5" = hidden {move-column-to-workspace = 5;};
    "Mod+Shift+6" = hidden {move-column-to-workspace = 6;};
    "Mod+Shift+7" = hidden {move-column-to-workspace = 7;};
    "Mod+Shift+8" = hidden {move-column-to-workspace = 8;};
    "Mod+Shift+9" = hidden {move-column-to-workspace = 9;};

    #--- Apps
    "Mod+Shift+S" = bind "Steam" {spawn = ["steam"];};
    "Mod+Shift+D" = lib.mkIf user.discord.goofcord (bind "Discord" {spawn = ["goofcord"];});
    "Mod+Shift+H" = bind "Heroic" {spawn = ["heroic"];};
    "Mod+Shift+G" = lib.mkIf user.gaming.lutris (bind "Lutris" {spawn = ["lutris"];});
    "Mod+Shift+Y" = bind "FreeTube" {spawn = ["freetube"];};
    #--- Opens the config in the default editor; focuses an open Zed window on it
    "Mod+Z" = bind "Editor on the config" {
      spawn =
        if chosen.textEditor.name == "zed"
        then
          [
            "nirius"
            "focus-or-spawn"
            "--app-id"
            "^dev\\.zed\\.Zed$"
            "--title"
            (lib.escapeRegex (baseNameOf machine.flakePath))
          ]
          ++ chosen.textEditor.launch
          ++ [machine.flakePath]
        else chosen.textEditor.launch ++ [machine.flakePath];
    };
    "Mod+B" = bind "Web browser" {spawn = chosen.browser.launch;};
    "Mod+E" = bind "Files" {spawn = chosen.fileManager.launch;};
    "Mod+Shift+M" = bind "Spotify" {spawn = ["spotify"];};
    "Ctrl+Alt+Delete" = bind "Resources (system monitor)" {spawn = ["resources"];};
    #--- Focuses NixOS Settings, or opens it
    "Mod+C" = bind "NixOS Settings" {
      spawn = ["nirius" "focus-or-spawn" "--app-id" "^dev\\.nixosconfig\\.Settings$" "nixos-settings"];
    };
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
