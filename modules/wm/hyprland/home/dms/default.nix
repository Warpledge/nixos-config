{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Restart dms.service when DMS changes
    };

    #--- Plugins
    # Mirrors the niri module. Any `settings` here makes plugin_settings.json a
    # read-only store link, so changes in a plugin's settings page no longer save.
    plugins = {
      # amdGpuMonitor is per machine: machines/eclipse/hardware/gpu.nix

      # The plugin stores its options as strings, booleans included.
      aiOverviewControl = {
        enable = user.claude.enable;
        settings = {
          providerSelection = "claude";
          pillProviders = "claude";
          languageOverride = "en_US";
          densityMode = "comfortable";
          pillMode = "auto";
          pillTooltip = "true";
          pillCompact = "false";
          showAntigravityModelDetails = "false";
          notifyThreshold = "85";
        };
      };

      quickCapture = {
        enable = true;
        settings = {
          toolbarPosition = "bottom";
          showToolbarBorder = false;
          show_shortcut_hints = true;
          color_palette_preset = "catppuccin";
        };
      };
    };

    #--- Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = false; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # khal calendar: 0.13.0 broken in nixpkgs
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
    (exec "SUPER + R" "dms restart" {}) # Restart DMS

    #--- Quick Capture: screenshots open in its editor
    (dms "Print" "quickCapture screenshot region edit") # Region Select
    (dms "SUPER + Print" "quickCapture screenshot window edit") # Focused Window
    (dms "SUPER + SHIFT + Print" "quickCapture screenshot full edit") # Focused Output
    (dms "CTRL + Print" "quickCapture screenshot all edit") # All Outputs
    # Scrolling Capture
    (dms "SUPER + CTRL + Print" "quickCapture screenshot scroll edit")

    #--- Quick Capture: recording
    # portal only: the gpu-screen-recorder screen/region modes capture via KMS,
    # which bypasses the no_screen_share rules.
    (dms "SUPER + End" "quickCapture recordToggle portal") # Toggle Recording

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
  #--- DMS Main and Clipboard Settings
  # Mirrors niri's settings.json, merged into files the settings GUI can save
  # to (wm/dms-mutable.nix). The theme path points at this user's home, not
  # the one the mirrored file names; the cursor size follows Stylix.
  dms.mutableFiles = let
    mirrored = lib.importJSON ./settings.json;
  in {
    "settings.json" = pkgs.writeText "dms-settings.json" (builtins.toJSON (mirrored
      // {
        currentThemeCategory = "custom";
        customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/stylix/theme.json";
        cursorSettings = mirrored.cursorSettings // {inherit (config.stylix.cursor) size;};
      }));
    "clsettings.json" = ./clsettings.json;
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms-plugin-registry.homeModules.default
    ../../../dms-mutable.nix
    ../../../dms-polkit
    {
      # Shared with the niri module, so a machine sets a plugin's settings
      # once for both WMs (the desktop's GPU widget); here DMS links them
      options.dms.pluginSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = {};
        description = "Settings per plugin name, passed to its plugins.<name>.settings.";
      };
      config.programs.dank-material-shell.plugins =
        lib.mapAttrs (_: settings: {inherit settings;}) config.dms.pluginSettings;
    }
  ];
}
