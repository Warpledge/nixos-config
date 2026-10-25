#=====================================================================#
# KYLERJ'S NIRI KEYBINDS (KDE PLASMA LAYOUT)
#=====================================================================#
#- kylerj's KDE Plasma shortcuts, translated to niri. A repo bind on one of
#- these keys is switched off by id; the repo's other binds stay.
{
  lib,
  pkgs,
  ...
}: let
  dms = action: ["dms" "ipc" "call"] ++ lib.splitString " " action;

  #--- Click a window to kill its process (KDE's xkill)
  killClicked = pkgs.writeShellScript "niri-kill-clicked" ''
    pid=$(niri msg --json pick-window | ${pkgs.jq}/bin/jq -r '.pid // empty')
    [ -n "$pid" ] && kill -9 "$pid"
  '';

  #--- power-saver -> balanced -> performance -> power-saver
  cyclePowerProfile = pkgs.writeShellScript "cycle-power-profile" ''
    case $(powerprofilesctl get) in
      power-saver) next=balanced ;;
      balanced) next=performance ;;
      *) next=power-saver ;;
    esac
    powerprofilesctl set "$next"
  '';

  #--- Touchpad on / off: touch-gestures.py (wm/) holds the touchpad while the
  # file isn't empty; niri's own switch would also stop the touchscreen gestures
  touchpadFile = "$HOME/.config/niri/touchpad-off";
  toggleTouchpad = pkgs.writeShellScript "toggle-touchpad" ''
    if [ -s "${touchpadFile}" ]; then
      : > "${touchpadFile}"
    else
      echo off > "${touchpadFile}"
    fi
  '';

  section = group: lib.mapAttrs (_: b: b // {inherit group;});
  # The title is what the Mod+/ cheatsheet (DMS) shows for the bind
  bind = key: title: action: {inherit key title action;};
  hidden = key: title: action: bind key title action // {hidden = true;};
  # Volume keys still work on the lock screen
  locked = key: title: cmd: hidden key title {spawn = cmd;} // {allowWhenLocked = true;};
in {
  #--------------------------------------------------------------------#
  #-- Repo Binds on KDE Keys
  #--------------------------------------------------------------------#
  #--- Mod+T (terminal-t) and Mod+Space (launcher) already match KDE
  niri.keybinds = lib.mkMerge [
    (lib.genAttrs [
      "system-monitor" # Ctrl+Alt+Delete
      "maximize-column" # Mod+F
      "wallpapers" # Mod+W
      "focus-left" # Mod+Left
      "focus-right" # Mod+Right
      "focus-up" # Mod+Up
      "focus-down" # Mod+Down
      "move-left" # Mod+Shift+Left
      "move-right" # Mod+Shift+Right
      "focus-monitor-left" # Mod+Alt+Left
      "focus-monitor-right" # Mod+Alt+Right
      "shrink-width" # Mod+Ctrl+Left
      "grow-width" # Mod+Ctrl+Right
      "shrink-height" # Mod+Ctrl+Up
      "grow-height" # Mod+Ctrl+Down
      "cycle-column-width" # Mod+G
      "browser" # Mod+B
    ] (_: {enable = false;}))

    #------------------------------------------------------------------#
    #-- KDE Binds
    #------------------------------------------------------------------#
    (section "KDE: Apps" {
      kde-task-manager =
        bind "Ctrl+Alt+Delete" "Task manager" {spawn = dms "processlist toggle";};
    })

    (section "KDE: Windows" {
      kde-fullscreen = bind "Mod+F" "Fullscreen" {fullscreen-window = {};};
      kde-float = bind "Mod+W" "Float / tile window" {toggle-window-floating = {};};
      kde-maximize = bind "Mod+BackSpace" "Maximize column on / off" {maximize-column = {};};
      kde-opacity =
        bind "Mod+Page_Up" "Window transparency on / off" {toggle-window-rule-opacity = {};};
      kde-opacity-down =
        hidden "Mod+Page_Down" "Window transparency on / off" {toggle-window-rule-opacity = {};};
      kde-wider = hidden "Mod+Equal" "Wider column" {set-column-width = "+10%";};
      kde-kill = bind "Alt+Shift+Q" "Kill a window (click it)" {spawn = ["${killClicked}"];};
    })

    #--- KDE quick tiling
    (section "KDE: Move" {
      kde-move-left = bind "Mod+Left" "Move left" {move-column-left = {};};
      kde-move-right = bind "Mod+Right" "Move right" {move-column-right = {};};
      kde-move-up =
        bind "Mod+Up" "Move up / to workspace above" {move-window-up-or-to-workspace-up = {};};
      kde-move-down = bind "Mod+Down" "Move down / to workspace below" {
        move-window-down-or-to-workspace-down = {};
      };
      kde-monitor-left =
        bind "Mod+Shift+Left" "Window to monitor left" {move-column-to-monitor-left = {};};
      kde-monitor-right =
        bind "Mod+Shift+Right" "Window to monitor right" {move-column-to-monitor-right = {};};
    })

    (section "KDE: Focus" {
      kde-focus-left = bind "Mod+Alt+Left" "Focus left" {focus-column-left = {};};
      kde-focus-right = bind "Mod+Alt+Right" "Focus right" {focus-column-right = {};};
      kde-focus-up =
        bind "Mod+Alt+Up" "Focus up / workspace above" {focus-window-or-workspace-up = {};};
      kde-focus-down =
        bind "Mod+Alt+Down" "Focus down / workspace below" {focus-window-or-workspace-down = {};};
    })

    #--- KDE desktops
    (section "KDE: Workspaces" {
      kde-workspace-1 = bind "Mod+F1" "Go to workspace 1-4" {focus-workspace = 1;};
      kde-workspace-2 = hidden "Mod+F2" "Go to workspace 2" {focus-workspace = 2;};
      kde-workspace-3 = hidden "Mod+F3" "Go to workspace 3" {focus-workspace = 3;};
      kde-workspace-4 = hidden "Mod+F4" "Go to workspace 4" {focus-workspace = 4;};
      kde-workspace-up = bind "Mod+Ctrl+Up" "Workspace above" {focus-workspace-up = {};};
      kde-workspace-down = bind "Mod+Ctrl+Down" "Workspace below" {focus-workspace-down = {};};
      kde-focus-monitor-left =
        bind "Mod+Ctrl+Left" "Focus monitor left" {focus-monitor-left = {};};
      kde-focus-monitor-right =
        bind "Mod+Ctrl+Right" "Focus monitor right" {focus-monitor-right = {};};
      kde-to-workspace-up =
        bind "Mod+Ctrl+Shift+Up" "Window to workspace above" {move-column-to-workspace-up = {};};
      kde-to-workspace-down = bind "Mod+Ctrl+Shift+Down" "Window to workspace below" {
        move-column-to-workspace-down = {};
      };
      kde-to-monitor-left =
        hidden "Mod+Ctrl+Shift+Left" "Window to monitor left" {move-column-to-monitor-left = {};};
      kde-to-monitor-right = hidden "Mod+Ctrl+Shift+Right" "Window to monitor right" {
        move-column-to-monitor-right = {};
      };
    })

    #--- KDE grid and present windows
    (section "KDE: Overview" {
      kde-overview = bind "Mod+G" "Overview" {toggle-overview = {};};
      kde-overview-f7 = hidden "Mod+F7" "Overview" {toggle-overview = {};};
    })

    #--- KDE Spectacle keys
    (section "KDE: Screenshots" {
      kde-shot-region =
        bind "Mod+Shift+S" "Screenshot region" {spawn = dms "quickCapture screenshot region edit";};
      kde-shot-window =
        bind "Mod+Shift+A" "Screenshot window" {spawn = dms "quickCapture screenshot window edit";};
      kde-shot-screen =
        bind "Mod+Shift+D" "Screenshot screen" {spawn = dms "quickCapture screenshot full edit";};
      kde-record =
        bind "Mod+Shift+R" "Start / stop recording" {spawn = dms "quickCapture recordToggle portal";};
    })

    (section "KDE: System" {
      kde-shortcuts-inhibit = bind "Mod+Shift+Escape" "Shortcuts to app on / off" {
        toggle-keyboard-shortcuts-inhibit = {};
      };
      kde-restart-shell = bind "Ctrl+Alt+BackSpace" "Restart shell" {spawn = ["dms" "restart"];};
      kde-power-profile = bind "Mod+B" "Next power profile" {spawn = ["${cyclePowerProfile}"];};
      # The folio's touchpad key sends F21 (hid-asus), XF86TouchpadToggle in xkb
      kde-touchpad =
        bind "XF86TouchpadToggle" "Touchpad on / off" {spawn = ["${toggleTouchpad}"];};
      # Volume in 1% steps, mic mute
      kde-volume-up =
        locked "Shift+XF86AudioRaiseVolume" "Volume up 1%" (dms "audio increment 1");
      kde-volume-down =
        locked "Shift+XF86AudioLowerVolume" "Volume down 1%" (dms "audio decrement 1");
      kde-mic-mute = locked "Mod+XF86AudioMute" "Mute microphone" (dms "audio micmute");
    })
  ];
}
