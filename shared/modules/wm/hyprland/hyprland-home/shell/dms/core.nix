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
  wayland.windowManager.hyprland.settings = {
    bind = [
      #--- DankMaterialShell Controls
      "SUPER, A, exec, dms ipc call spotlight toggle" # Application Launcher
      "SUPER, V, exec, dms ipc call clipboard toggle" # Clipboard Manager
      "SUPER, P, exec, dms ipc call processlist toggle" # Task Manager
      "SUPER, comma, exec, dms ipc call settings toggle" # Settings
      "SUPER, N, exec, dms ipc call notepad toggle" # Notepad
      "SUPER, K, exec, dms ipc call powermenu toggle" # Power Menu
      "SUPER, W, exec, dms ipc dankdash wallpaper" # Browse Wallpapers
      "SUPER SHIFT, N, exec, dms ipc call night toggle" # Night Mode Toggle
      "SUPER, L, exec, dms ipc call lock lock" # Toggle lock screen
      "SUPER, I, exec, dms ipc call inhibit toggle" # Toggle idle inhibit
      "SUPER, slash, exec, dms ipc call keybinds toggle hyprland" # Show Keybind Cheatsheet
    ];

    bindl = [
      #--- Audio controls
      ",XF86AudioRaiseVolume, exec, dms ipc call audio increment 3" # Volume Up
      ",XF86AudioLowerVolume, exec, dms ipc call audio decrement 3" # Volume Down
      ",XF86AudioMute, exec, dms ipc call audio mute" # Mute Audio
      ",XF86AudioMicMute, exec, dms ipc call audio micmute" # Mute Microphone

      #--- Brightness controls
      ",XF86MonBrightnessUp, exec, dms ipc call brightness increment 5" # Brightness Up
      ",XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5" # Brightness Down
    ];
  };

  #--------------------------------------------------------------------#
  #-- DECLARATIVE DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  home.file.".config/DankMaterialShell/settings.json" = {
    text = builtins.toJSON (lib.importJSON ./settings.json);
  };
}
