#=====================================================================#
# COSMIC KEYBINDS
#=====================================================================#
{
  lib,
  pkgs,
  ...
}: let
  #--------------------------------------------------------------------#
  #-- Screen Recording Scripts
  #--------------------------------------------------------------------#
  # Scripts, not inline Spawn strings: a `$` in a Spawn breaks the whole
  # shortcuts file (see CLAUDE.md).
  recordStart = pkgs.writeShellScriptBin "cosmic-record-start" ''
    mkdir -p ~/Videos
    notify-send -i media-record 'Recording Started' 'Saving to ~/Videos'
    exec gpu-screen-recorder -w screen -f 30 -k h264 -q medium \
      -a "$(pactl get-default-sink).monitor" \
      -o ~/Videos/clip-"$(date +%Y%m%d-%H%M%S)".mp4
  '';

  recordStop = pkgs.writeShellScriptBin "cosmic-record-stop" ''
    pkill -INT -f gpu-screen-recorder
    notify-send -i media-playback-stop 'Recording Stopped' 'Clip saved to ~/Videos'
  '';

  #--------------------------------------------------------------------#
  #-- RON Action Constructors
  #--------------------------------------------------------------------#
  #--- Nullary: Close
  plain = variant: {
    __type = "enum";
    inherit variant;
  };

  #--- One scalar: Spawn("kitty"), Workspace(1)
  arg = variant: value: {
    __type = "enum";
    inherit variant;
    value = [value];
  };

  #--- One nested enum: System(Launcher), Focus(Left)
  enumArg = variant: inner: arg variant (plain inner);

  #--- Spawn with a Settings-visible label
  spawn = key: desc: cmd: {
    inherit key;
    description = {
      __type = "optional";
      value = desc;
    };
    action = arg "Spawn" cmd;
  };
in {
  home.packages = [recordStart recordStop];

  #--------------------------------------------------------------------#
  #-- Custom Shortcuts
  #--------------------------------------------------------------------#
  # Overrides only — cosmic-comp ships ~130 compiled-in defaults that need no
  # declaring. A custom entry on the same key wins; `plain "Disable"` kills a
  # default outright.
  wayland.desktopManager.cosmic.shortcuts =
    [
      #--------------------------------------------------------------------#
      #-- Window Management
      #--------------------------------------------------------------------#
      (spawn "Super+Return" "Terminal" "kitty")
      {
        key = "Super+F";
        action = plain "Maximize";
      }
      {
        key = "Super+Shift+F";
        action = plain "Fullscreen";
      }
      {
        key = "Super+space";
        action = plain "ToggleWindowFloating";
      }
      {
        key = "Super+Tab";
        action = enumArg "System" "WorkspaceOverview";
      }
      {
        key = "Super+A";
        action = enumArg "System" "Launcher";
      }
      {
        key = "Super+Shift+A";
        action = enumArg "System" "AppLibrary";
      }

      #--------------------------------------------------------------------#
      #-- Applications
      #--------------------------------------------------------------------#
      (spawn "Super+B" "Zen Browser" "zen-beta")
      (spawn "Super+E" "Files" "nautilus")
      (spawn "Super+Z" "Zed" "zeditor")
      (spawn "Super+Shift+S" "Steam" "steam")
      (spawn "Super+Shift+D" "Discord" "vesktop")
      (spawn "Super+Shift+H" "Heroic" "heroic")
      (spawn "Super+Shift+G" "Lutris" "lutris")
      (spawn "Super+Shift+Y" "Grayjay" "Grayjay")
      (spawn "Super+Shift+M" "Spotify" "spotify")

      #--------------------------------------------------------------------#
      #-- Waydroid
      #--------------------------------------------------------------------#
      (spawn "Super+Shift+W" "Start Waydroid" "waydroid session start")
      (spawn "Super+Ctrl+W" "Stop Waydroid" "waydroid session stop")

      #--------------------------------------------------------------------#
      #-- Media & Capture
      #--------------------------------------------------------------------#
      # Play/pause, next, prev, volume and mute are already bound upstream.
      (spawn "XF86AudioStop" "Pause Playback" "playerctl pause")
      (spawn "Super+Home" "Start Recording" "cosmic-record-start")
      (spawn "Super+End" "Stop Recording" "cosmic-record-stop")
    ]
    #--------------------------------------------------------------------#
    #-- Workspaces
    #--------------------------------------------------------------------#
    ++ lib.concatMap (n: [
      {
        key = "Super+${toString n}";
        action = arg "Workspace" n;
      }
      {
        key = "Super+Shift+${toString n}";
        action = arg "MoveToWorkspace" n;
      }
    ]) (lib.range 1 9);
}
