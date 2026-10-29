#=====================================================================#
# NIRI KEYBINDS
#=====================================================================#
{
  lib,
  machine,
  user,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Niri Keybindings
  #--------------------------------------------------------------------#
  # Ids are what overrides and machine files name (option in keybinds.nix)
  niri.keybinds = let
    # The user's defaultApps, for the app binds
    chosen = (import ../../../../../lib/default-apps.nix {inherit lib;}).forUser user;
    railApps = (import ../dms/plugins/side-rail/apps.nix {inherit lib user machine;}).apps;
    inRail = id: lib.any (a: a.id == id) railApps;
    railToggle = id: ["dms" "ipc" "call" "sideRail" "toggleApp" id];
    # Each bind in a section gets its group, the heading Omni Settings shows
    section = group: lib.mapAttrs (_: b: b // {inherit group;});
    # The title is what the Mod+/ cheatsheet (DMS) shows for the bind
    bind = key: title: action: {inherit key title action;};
    # Left out of the cheatsheet
    hidden = key: title: action: bind key title action // {hidden = true;};
    # A hidden spawn bind that still fires while the DMS lock screen is up
    locked = key: title: cmd: hidden key title {spawn = cmd;} // {allowWhenLocked = true;};
    numbers = lib.range 1 9;
  in
    lib.mkMerge [
      #--- Media Player Controls
      (section "Media" {
        play-pause = locked "XF86AudioPlay" "Play / pause" ["playerctl" "play-pause"];
        pause = locked "XF86AudioStop" "Pause" ["playerctl" "pause"];
        previous-track = locked "XF86AudioPrev" "Previous track" ["playerctl" "previous"];
        next-track = locked "XF86AudioNext" "Next track" ["playerctl" "next"];
      })

      #--- Applications
      # Screenshot binds live with the other DMS commands in dms/default.nix
      (section "Apps" {
        terminal = bind "Mod+Return" "Terminal" {spawn = chosen.terminal.launch;};
        terminal-t = bind "Mod+T" "Terminal" {spawn = chosen.terminal.launch;};
      })

      (section "Windows" {
        close-window = bind "Mod+Q" "Close window" {close-window = {};};
        cycle-column-width =
          bind "Mod+G" "Cycle column width" {switch-preset-column-width = {};};
        fill-empty-space =
          bind "Mod+D" "Fill empty space" {expand-column-to-available-width = {};};
        maximize-column = bind "Mod+F" "Maximize column" {maximize-column = {};};
        fullscreen = bind "Mod+Shift+F" "Fullscreen" {fullscreen-window = {};};
        maximize-to-edges =
          bind "Mod+shift+G" "Maximize to screen edges" {maximize-window-to-edges = {};};
        toggle-floating =
          bind "Mod+grave" "Float / tile window" {toggle-window-floating = {};};
        switch-focus-floating = bind "Mod+Shift+Space" "Switch focus floating / tiled" {
          switch-focus-between-floating-and-tiling = {};
        };
        # Turn the window's opacity rule (rules.nix) off and on
        toggle-opacity = bind "Mod+Shift+T" "Window transparency on / off" {
          toggle-window-rule-opacity = {};
        };
        # Same, and also works on apps without an opacity rule (blur-presets.nix)
        toggle-opacity-any =
          bind "Mod+Shift+Y" "Transparency on / off, any app" {spawn = "niri-opacity-toggle";};
        # Cycle the blur and translucency presets (blur-presets.nix)
        blur-preset = bind "Mod+Y" "Cycle blur preset" {spawn = "niri-blur-preset";};
        # Takes shortcuts back from an app that inhibits them
        shortcuts-inhibit =
          bind "Mod+Escape" "Take shortcuts back from app" {
            toggle-keyboard-shortcuts-inhibit = {};
          }
          // {allowInhibiting = false;};
      })

      (section "Resize" {
        column-third = bind "Mod+Alt+1" "Column width 1/3" {set-column-width = "33.333%";};
        column-half = bind "Mod+Alt+2" "Column width 1/2" {set-column-width = "50%";};
        column-two-thirds =
          bind "Mod+Alt+3" "Column width 2/3" {set-column-width = "66.667%";};

        narrower-column = bind "Mod+Minus" "Narrower column" {set-column-width = "-10%";};
        wider-column = bind "Mod+Plus" "Wider column" {set-column-width = "+10%";};
        shorter-window =
          bind "Mod+Shift+Minus" "Shorter window" {set-window-height = "-10%";};
        taller-window = bind "Mod+Shift+Plus" "Taller window" {set-window-height = "+10%";};
      })

      (section "Focus" {
        scroll-focus-left =
          hidden "Mod+WheelScrollUp" "Focus left (scroll)" {focus-column-left = {};};
        scroll-focus-right =
          hidden "Mod+WheelScrollDown" "Focus right (scroll)" {focus-column-right = {};};
        scroll-workspace-up = hidden "Mod+Shift+WheelScrollUp" "Workspace above (scroll)" {
          focus-workspace-up = {};
        };
        scroll-workspace-down = hidden "Mod+Shift+WheelScrollDown" "Workspace below (scroll)" {
          focus-workspace-down = {};
        };

        #--- Focus Window
        focus-left = bind "Mod+Left" "Focus left" {focus-column-left = {};};
        focus-right = bind "Mod+Right" "Focus right" {focus-column-right = {};};
        # Walk the windows of a stacked or tabbed column before leaving the workspace
        focus-up = bind "Mod+Up" "Focus up / workspace above" {
          focus-window-or-workspace-up = {};
        };
        focus-down = bind "Mod+Down" "Focus down / workspace below" {
          focus-window-or-workspace-down = {};
        };
      })

      #--- Window Movement
      (section "Movement" {
        move-left = bind "Mod+Shift+Left" "Move left" {move-column-left = {};};
        move-right = bind "Mod+Shift+Right" "Move right" {move-column-right = {};};
        move-up = bind "Mod+Shift+Up" "Move up / to workspace above" {
          move-window-up-or-to-workspace-up = {};
        };
        move-down = bind "Mod+Shift+Down" "Move down / to workspace below" {
          move-window-down-or-to-workspace-down = {};
        };
      })

      #--- Monitors
      (section "Monitors" {
        focus-monitor-left =
          bind "Mod+Alt+Left" "Focus monitor left" {focus-monitor-left = {};};
        focus-monitor-right =
          bind "Mod+Alt+Right" "Focus monitor right" {focus-monitor-right = {};};
        move-to-monitor-left = bind "Mod+Alt+Shift+Left" "Move to monitor left" {
          move-column-to-monitor-left = {};
        };
        move-to-monitor-right = bind "Mod+Alt+Shift+Right" "Move to monitor right" {
          move-column-to-monitor-right = {};
        };
      })

      #--- Column Stacking
      (section "Columns" {
        # Pull the neighbouring window into this column, or push this one out of it
        stack-left = bind "Mod+BracketLeft" "Stack / unstack left" {
          consume-or-expel-window-left = {};
        };
        stack-right = bind "Mod+BracketRight" "Stack / unstack right" {
          consume-or-expel-window-right = {};
        };
        tabbed-column = bind "Mod+Backslash" "Tabbed column on / off" {
          toggle-column-tabbed-display = {};
        };
      })

      #--- Window Resize
      (section "Resize" {
        shrink-width = bind "Mod+Ctrl+Left" "Shrink width" {set-column-width = "-80";};
        grow-width = bind "Mod+Ctrl+Right" "Grow width" {set-column-width = "+80";};
        shrink-height = bind "Mod+Ctrl+Up" "Shrink height" {set-window-height = "-80";};
        grow-height = bind "Mod+Ctrl+Down" "Grow height" {set-window-height = "+80";};
      })

      (section "Windows" {
        overview = bind "Mod+Tab" "Overview" {toggle-overview = {};};
        center-column = bind "Mod+J" "Center column" {center-column = {};};
        cycle-window-height =
          bind "Mod+H" "Cycle window height" {switch-preset-window-height = {};};
        reset-window-height =
          bind "Mod+Shift+H" "Reset window height" {reset-window-height = {};};
      })

      #--- Workspace Navigation (Number Keys)
      # 2-9 are hidden so the cheatsheet lists the number keys once
      (section "Workspaces" (lib.listToAttrs (map (n: let
        name = toString n;
      in
        lib.nameValuePair "workspace-${name}" (
          if n == 1
          then bind "Mod+1" "Go to workspace 1-9" {focus-workspace = 1;}
          else hidden "Mod+${name}" "Go to workspace ${name}" {focus-workspace = n;}
        ))
      numbers)))

      #--- Move Window to Workspace (Number Keys)
      # focus = false keeps the view on the current workspace
      (section "Workspaces" (lib.listToAttrs (map (n: let
        name = toString n;
      in
        lib.nameValuePair "to-workspace-${name}" (
          if n == 1
          then bind "Mod+Shift+1" "Send window to workspace 1-9" {move-column-to-workspace = [{focus = false;} 1];}
          else
            hidden "Mod+Shift+${name}" "Send window to workspace ${name}" {
              move-column-to-workspace = [{focus = false;} n];
            }
        ))
      numbers)))

      #--- Apps
      (section "Apps" ({
          steam = bind "Mod+Ctrl+S" "Steam" {spawn = ["steam"];};
          heroic = bind "Mod+Ctrl+H" "Heroic" {spawn = ["heroic"];};
          freetube = bind "Mod+Ctrl+Y" "FreeTube" {spawn = ["freetube"];};
          #--- Opens the config in the default editor; focuses an open Zed window on it
          config-editor = bind "Mod+Z" "Editor on the config" {
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
          browser = bind "Mod+B" "Web browser" {spawn = chosen.browser.launch;};
          files = bind "Mod+E" "Files" {spawn = chosen.fileManager.launch;};
          spotify = bind "Mod+Ctrl+M" "Spotify" {spawn = ["spotify"];};
          system-monitor =
            bind "Ctrl+Alt+Delete" "Resources (system monitor)" {spawn = ["resources"];};
          #--- Omni Settings: the DMS panel (omni-settings/plugin/), or the window
          omni-settings = bind "Mod+S" "Omni Settings panel" {
            spawn = ["dms" "ipc" "call" "omniSettings" "toggle"];
          };
        }
        // lib.optionalAttrs (user.discord.goofcord || user.discord.vesktop) {
          discord = bind "Mod+Ctrl+D" "Discord" {
            spawn = [
              (
                if user.discord.vesktop
                then "vesktop"
                else "goofcord"
              )
            ];
          };
        }
        // lib.optionalAttrs user.gaming.lutris {
          lutris = bind "Mod+Ctrl+G" "Lutris" {spawn = ["lutris"];};
        }
        #--- Claude / OpenCode Desktop show or hide the side rail on them when it has
        #--- them, else focus an open window instead of starting another
        // lib.optionalAttrs user.claudeDesktop.enable {
          claude-desktop = bind "Mod+C" "Claude Desktop" {
            spawn =
              if inRail "claude-desktop"
              then railToggle "claude-desktop"
              else ["nirius" "focus-or-spawn" "--app-id" "^com\\.anthropic\\.Claude$" "claude-desktop"];
          };
        }
        // lib.optionalAttrs user.opencodeDesktop.enable {
          opencode-desktop = bind "Mod+X" "OpenCode Desktop" {
            spawn =
              if inRail "opencode-desktop"
              then railToggle "opencode-desktop"
              else ["nirius" "focus-or-spawn" "--app-id" "^ai\\.opencode\\.desktop$" "opencode-desktop"];
          };
        }
        #--- The side rail of docked apps on the left edge (dms/plugins/side-rail)
        // lib.optionalAttrs (railApps != []) {
          side-rail = bind "Mod+A" "Side rail" {spawn = ["dms" "ipc" "call" "sideRail" "toggle"];};
        }))
    ];
}
