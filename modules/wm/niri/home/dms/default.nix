{
  config,
  pkgs,
  inputs,
  lib,
  user,
  ...
}: let
  # The theme path in the mirrored file names one home folder; point it at this user's
  settings =
    lib.importJSON ./settings.json
    // {customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/catppuccin/theme.json";};
  # Same shape the DMS module would link read-only (distro/nix/home.nix)
  pluginSettings = (pkgs.formats.json {}).generate "plugin_settings.json" (
    lib.mapAttrs (name: p: {enabled = p.enable;} // config.dms.pluginSettings.${name} or {})
    (lib.filterAttrs (_: p: p.enable) config.programs.dank-material-shell.plugins)
  );
in {
  #--------------------------------------------------------------------#
  #-- DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  programs.dank-material-shell = {
    enable = true;

    #--- Startup
    # Under systemd, not niri spawn-at-startup: `dms restart` and the power menu's
    # restart only relaunch the shell when dms.service is active — otherwise they
    # signal the process and nothing brings it back.
    systemd.enable = true;
    niri.enableSpawn = false;

    #--- Plugins
    # plugin_settings.json is written as a normal file (dmsPluginSettings below),
    # from dms.pluginSettings: those win on each rebuild, keys a plugin saves
    # itself are kept.
    managePluginSettings = false;
    plugins = {
      # amdGpuMonitor is per machine: machines/eclipse/hardware/gpu.nix
      aiOverviewControl.enable = user.claude.enable;
      quickCapture.enable = true;

      # A bar widget: its IPC target only exists while it sits in a bar
      # (rightWidgets in settings.json).
      clipboardPlus.enable = true;

      wallpaperCarousel.enable = user.wallpaper == "carousel";

      # Runs linux-wallpaperengine itself; picks are saved in plugin_settings.json
      linuxWallpaperEngine.enable = user.wallpaper == "engine";
    };

    #--- Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = false; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # khal calendar: 0.13.0 broken in nixpkgs
    enableClipboardPaste = true; # Clipboard pasting via wtype
  };

  #--- Plugin settings, here rather than in plugins.<name>.settings, which DMS
  #--- warns it ignores while managePluginSettings is off
  dms.pluginSettings = {
    # The plugin stores its options as strings, booleans included.
    aiOverviewControl = {
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

    quickCapture = {
      toolbarPosition = "bottom";
      showToolbarBorder = false;
      show_shortcut_hints = true;
      color_palette_preset = "catppuccin";
    };

    wallpaperCarousel.wallpaperDirectory = "${../../../../theme/wallpapers}";

    clipboardPlus = {
      backgroundOpacity = 80; # dim behind the panel, 0-80
      panelOpacityClipboard = 80;
      panelOpacityPinned = 80;
      emojiUnicodeEnabled = false;
    };
  };

  #--------------------------------------------------------------------#
  #-- DankMaterialShell NIRI KEYBINDS --#
  #--------------------------------------------------------------------#
  programs.niri.settings.binds = let
    dms = action: ["dms" "ipc" "call"] ++ (lib.splitString " " action);
    # A DMS bind titled for the Mod+/ cheatsheet
    dmsBind = title: action: {
      action.spawn = dms action;
      hotkey-overlay.title = title;
    };
    # Hardware keys: still fire while the lock screen is up, left off the cheatsheet
    dmsLocked = action: {
      action.spawn = dms action;
      allow-when-locked = true;
      hotkey-overlay.hidden = true;
    };
  in {
    #--- DankMaterialShell Controls
    "Mod+A" = dmsBind "App launcher" "spotlight toggle";
    "Mod+V" = dmsBind "Clipboard history" "clipboardPlus togglePanel";
    "Mod+P" = dmsBind "Task manager" "processlist toggle";
    "Mod+Comma" = dmsBind "Shell settings" "settings toggle";
    "Mod+N" = dmsBind "Notepad" "notepad toggle";
    "Mod+K" = dmsBind "Power menu" "powermenu toggle";
    "Mod+W" = dmsBind "Wallpapers" (
      if user.wallpaper == "engine"
      then "linuxWallpaperEngine picker"
      else "wallpaperCarousel toggle"
    );
    "Mod+Shift+N" = dmsBind "Night mode on / off" "night toggle";
    "Mod+L" = dmsBind "Lock screen" "lock lock";
    "Mod+I" = dmsBind "Keep awake on / off" "inhibit toggle";
    "Mod+slash" = dmsBind "Show keybinds" "keybinds toggle niri";
    "Mod+R" = {
      action.spawn = ["dms" "restart"];
      hotkey-overlay.title = "Restart shell";
    };

    #--- Quick Capture: screenshots open in its editor
    "Print" = dmsBind "Screenshot region" "quickCapture screenshot region edit";
    "Mod+Print" = dmsBind "Screenshot window" "quickCapture screenshot window edit";
    "Mod+Shift+Print" = dmsBind "Screenshot monitor" "quickCapture screenshot full edit";
    "Ctrl+Print" = dmsBind "Screenshot all monitors" "quickCapture screenshot all edit";
    "Mod+Ctrl+Print" =
      dmsBind "Scrolling screenshot" "quickCapture screenshot scroll edit";

    #--- Quick Capture: recording
    # portal only: the gpu-screen-recorder screen/region modes capture via KMS,
    # which bypasses niri's block-out-from rules.
    "Mod+End" = dmsBind "Start / stop recording" "quickCapture recordToggle portal";

    #--- Audio controls
    "XF86AudioRaiseVolume" = dmsLocked "audio increment 3"; # Volume Up
    "XF86AudioLowerVolume" = dmsLocked "audio decrement 3"; # Volume Down
    "XF86AudioMute" = dmsLocked "audio mute"; # Mute Audio
    "XF86AudioMicMute" = dmsLocked "audio micmute"; # Mute Microphone

    #--- Brightness controls
    "XF86MonBrightnessUp" = {
      action.spawn = dms "brightness increment 5";
      hotkey-overlay.hidden = true;
    };
    "XF86MonBrightnessDown" = {
      action.spawn = dms "brightness decrement 5";
      hotkey-overlay.hidden = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- DECLARATIVE DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  #--- DMS Main and Clipboard Settings
  # Merged into files the settings GUI can save to (wm/dms-mutable.nix)
  dms.mutableFiles = {
    "settings.json" = pkgs.writeText "dms-settings.json" (builtins.toJSON (settings
      # linux-wallpaperengine draws the wallpaper instead
      // lib.optionalAttrs (user.wallpaper == "engine") {
        screenPreferences.wallpaper = [];
        blurredWallpaperLayer = false;
      }
      # A machine's own keys (bars per monitor, lock timeout), from its wm/niri.nix
      // config.dms.extraSettings));
    "clsettings.json" = ./clsettings.json;
  };
  # linux-wallpaperengine owns the wallpaper, so the GUI can't take it back
  dms.lockedSettings = lib.optionals (user.wallpaper == "engine") [
    ["screenPreferences" "wallpaper"]
    ["blurredWallpaperLayer"]
  ];

  #--- Keybinds and monitors the GUI sets
  # Its binds override the repo's (binds.kdl loads after hm.kdl). niri takes the
  # first output block per monitor, so outputs.kdl loads before hm.kdl.
  dms.writableFiles = ["niri/dms/binds.kdl" "niri/dms/outputs.kdl"];
  programs.dank-material-shell.niri.includes.filesToInclude = [
    "alttab"
    "binds"
    "colors"
    "cursor"
    "layout"
    "windowrules"
    "wpblur"
  ];
  xdg.configFile.niri-config-dms.text = lib.mkBefore ''
    include optional=true "dms/outputs.kdl"
  '';

  home.file = {
    ".config/DankMaterialShell/cheatsheets/niri-dms.json" = {
      source = ./niri-cheatsheet.json;
    };

    #--- Niri KDL configuration files (auto-generated by home-manager)
    ".config/niri/dms/colors.kdl" = {
      text = "// Colors configured via Catppuccin theme\n";
    };

    ".config/niri/dms/alttab.kdl" = {
      text = "// Alt-Tab configuration (DMS)\n";
    };

    ".config/niri/dms/layout.kdl" = {
      text = "// Layout configuration (DMS)\n";
    };

    ".config/niri/dms/wpblur.kdl" = {
      # Blur and translucency come from the Mod+T preset (core/blur-presets.nix)
      text = ''
        include optional=true "${config.xdg.configHome}/niri/dms/blur-preset.kdl"
      '';
    };
  };

  #--- DMS Plugin Settings
  # Declared settings merged over the live file, so plugins can still save
  home.activation.dmsPluginSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
    f="${config.xdg.configHome}/DankMaterialShell/plugin_settings.json"
    if [[ -v DRY_RUN ]]; then
      echo "Would merge ${pluginSettings} into $f"
    else
      if [[ -s "$f" ]]; then
        merged="$(${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$f" ${pluginSettings})"
      else
        merged="$(cat ${pluginSettings})"
      fi
      rm -f "$f"
      mkdir -p "$(dirname "$f")"
      printf '%s\n' "$merged" > "$f"
    fi
  '';

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.dms-plugin-registry.homeModules.default
    ../../../dms-mutable.nix
    {
      # Not DMS's own programs.dank-material-shell.settings, which would write
      # the same file
      options.dms.extraSettings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Keys merged over settings.json on one machine.";
      };
      # Hyprland's DMS module declares the same option
      options.dms.pluginSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = {};
        description = "Settings per plugin name, merged into plugin_settings.json.";
      };
    }
  ];
}
