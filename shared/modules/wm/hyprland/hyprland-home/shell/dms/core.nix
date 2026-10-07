{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  #--------------------------------------------------------------------#
  #-- DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dank-material-shell changes
    };

    #--- Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = false; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # Calendar integration (khal) - disabled: khal-0.13.0 broken in nixpkgs
    enableClipboardPaste = true; # Pasting items from the clipboard (wtype)
  };

  #--------------------------------------------------------------------#
  #-- DankMaterialShell HYPRLAND KEYBINDS --#
  #--------------------------------------------------------------------#
  wayland.windowManager.hyprland.settings.bind = let
    str = lib.generators.toLua {};
    exec = keys: cmd: opts: {
      _args =
        [keys (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${str cmd})")]
        ++ lib.optional (opts != {}) opts;
    };
    dms = keys: action: exec keys "dms ipc call ${action}" {};
    dmsLocked = keys: action: exec keys "dms ipc call ${action}" {locked = true;};
  in [
    #--- DankMaterialShell Controls
    (dms "SUPER + A" "spotlight toggle") # Application Launcher
    (dms "SUPER + V" "clipboard toggle") # Clipboard Manager
    (dms "SUPER + P" "processlist toggle") # Task Manager
    (dms "SUPER + comma" "settings toggle") # Settings
    (dms "SUPER + N" "notepad toggle") # Notepad
    (dms "SUPER + K" "powermenu toggle") # Power Menu
    (dms "SUPER + W" "dankdash wallpaper") # Browse Wallpapers
    (dms "SUPER + SHIFT + N" "night toggle") # Night Mode Toggle
    (dms "SUPER + L" "lock lock") # Toggle lock screen
    (dms "SUPER + I" "inhibit toggle") # Toggle idle inhibit
    (dms "SUPER + slash" "keybinds toggle hyprland") # Show Keybind Cheatsheet

    #--- Audio controls (locked: work on the lock screen)
    (dmsLocked "XF86AudioRaiseVolume" "audio increment 3") # Volume Up
    (dmsLocked "XF86AudioLowerVolume" "audio decrement 3") # Volume Down
    (dmsLocked "XF86AudioMute" "audio mute") # Mute Audio
    (dmsLocked "XF86AudioMicMute" "audio micmute") # Mute Microphone

    #--- Brightness controls
    (dmsLocked "XF86MonBrightnessUp" "brightness increment 5") # Brightness Up
    (dmsLocked "XF86MonBrightnessDown" "brightness decrement 5") # Brightness Down
  ];

  #--------------------------------------------------------------------#
  #-- DECLARATIVE DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  home.file.".config/DankMaterialShell/settings.json" = {
    text = builtins.toJSON (lib.importJSON ./settings.json);
  };
}
