{
  config,
  pkgs,
  inputs,
  lib,
  user,
  machine,
  ...
}: let
  sideRail = import ./plugins/side-rail/apps.nix {inherit lib user machine;};
  # The theme path in the mirrored file names one home folder; point it at this user's.
  # The cursor size follows Stylix (cursorSize in the machine's settings.nix).
  mirrored = lib.importJSON ./settings.json;
  settings =
    mirrored
    // {
      currentThemeCategory = "custom";
      customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/catppuccin-crust/theme.json";
      cursorSettings = mirrored.cursorSettings // {inherit (config.stylix.cursor) size;};
    }
    // inputDefaults;
  #--- What DMS writes to niri/dms/input.kdl until its Mouse & Touchpad and
  #--- Keyboard pages change it. DMS leaves a flag out when it's off rather than
  #--- writing `false`, so core/settings.nix must not set these.
  inputDefaults = {
    mouseAccelProfile = "flat";
    touchpadAccelProfile = "adaptive";
    touchpadScrollMethod = "two-finger";
    touchpadTapToClick = true;
    touchpadNaturalScroll = true;
    touchpadDisableWhileTyping = true;
    touchpadMiddleEmulation = true; # left+right click together = middle click
    keyboardNumlock = true;
  };
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

      quickCapture.enable = true;

      # Omni Settings' QML front end as a slideout (Mod+S)
      omniSettings.src = "${config.omni-settings.package}/share/omni-settings/plugin";

      # Bar widgets: a running rebuild, and the config repo's git state read
      # through Omni Settings' backend, which shares its GitHub limit
      rebuildStatus.src = ./plugins/rebuild-status;
      gitStatus.src = pkgs.runCommand "dms-git-status" {} ''
        cp -r ${./plugins/git-status} $out
        chmod -R u+w $out
        substituteInPlace $out/GitStatusWidget.qml --subst-var-by backend \
          ${config.omni-settings.package}/bin/omni-settings-backend
      '';

      # The Mod+A rail of docked apps, with its app list baked in
      sideRail = {
        enable = sideRail.apps != [];
        src = pkgs.runCommand "dms-side-rail" {} ''
          mkdir $out
          cp ${./plugins/side-rail/plugin.json} $out/plugin.json
          substitute ${./plugins/side-rail/SideRail.qml} $out/SideRail.qml \
            --subst-var-by config ${lib.escapeShellArg (builtins.toJSON sideRail)}
        '';
      };

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
    enableDynamicTheming = true; # matugen: writes each app's colours from the DMS theme
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # khal calendar: 0.13.0 broken in nixpkgs
    enableClipboardPaste = true; # Clipboard pasting via wtype
  };

  #--- Plugin settings, here rather than in plugins.<name>.settings, which DMS
  #--- warns it ignores while managePluginSettings is off
  dms.pluginSettings = {
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
  # Ids are what overrides name (option in core/keybinds.nix)
  niri.keybinds = let
    dms = action: ["dms" "ipc" "call"] ++ (lib.splitString " " action);
    # A DMS bind titled for the Mod+/ cheatsheet
    dmsBind = key: title: action: {
      inherit key title;
      action.spawn = dms action;
      group = "Shell";
    };
    # Hardware keys: still fire while the lock screen is up, left off the cheatsheet
    dmsLocked = key: title: action:
      dmsBind key title action
      // {
        allowWhenLocked = true;
        hidden = true;
        group = "Media";
      };
  in {
    #--- DankMaterialShell Controls
    launcher = dmsBind "Mod+space" "App launcher" "spotlight toggle";
    clipboard = dmsBind "Mod+V" "Clipboard history" "clipboardPlus togglePanel";
    task-manager = dmsBind "Mod+P" "Task manager" "processlist toggle";
    shell-settings = dmsBind "Mod+Comma" "Shell settings" "settings toggle";
    notepad = dmsBind "Mod+N" "Notepad" "notepad toggle";
    power-menu = dmsBind "Mod+K" "Power menu" "powermenu toggle";
    wallpapers = dmsBind "Mod+W" "Wallpapers" (
      if user.wallpaper == "engine"
      then "linuxWallpaperEngine picker"
      else "wallpaperCarousel toggle"
    );
    lock-screen = dmsBind "Mod+L" "Lock screen" "lock lock";
    show-keybinds = dmsBind "Mod+slash" "Show keybinds" "keybinds toggle niri";
    restart-shell = {
      key = "Mod+R";
      title = "Restart shell";
      action.spawn = ["dms" "restart"];
      group = "Shell";
    };

    #--- Quick Capture: screenshots open in its editor
    screenshot-region =
      dmsBind "Print" "Screenshot region" "quickCapture screenshot region edit";
    screenshot-window =
      dmsBind "Mod+Print" "Screenshot window" "quickCapture screenshot window edit";
    screenshot-monitor =
      dmsBind "Mod+Shift+Print" "Screenshot monitor" "quickCapture screenshot full edit";
    screenshot-all =
      dmsBind "Ctrl+Print" "Screenshot all monitors" "quickCapture screenshot all edit";
    screenshot-scroll =
      dmsBind "Mod+Ctrl+Print" "Scrolling screenshot" "quickCapture screenshot scroll edit";

    #--- Quick Capture: recording
    # portal only: the gpu-screen-recorder screen/region modes capture via KMS,
    # which bypasses niri's block-out-from rules.
    record = dmsBind "Mod+End" "Start / stop recording" "quickCapture recordToggle portal";

    #--- Audio controls
    volume-up = dmsLocked "XF86AudioRaiseVolume" "Volume up" "audio increment 3";
    volume-down = dmsLocked "XF86AudioLowerVolume" "Volume down" "audio decrement 3";
    mute = dmsLocked "XF86AudioMute" "Mute audio" "audio mute";
    mic-mute = dmsLocked "XF86AudioMicMute" "Mute microphone" "audio micmute";

    #--- Brightness controls
    brightness-up =
      dmsBind "XF86MonBrightnessUp" "Brightness up" "brightness increment 5"
      // {hidden = true;};
    brightness-down =
      dmsBind "XF86MonBrightnessDown" "Brightness down" "brightness decrement 5"
      // {hidden = true;};
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
  # colors.kdl is matugen's (theme/matugen.nix)
  dms.writableFiles = ["niri/dms/binds.kdl" "niri/dms/outputs.kdl" "niri/dms/colors.kdl"];
  programs.dank-material-shell.niri.includes.filesToInclude = [
    "alttab"
    "binds"
    "colors"
    "cursor"
    "input" # mouse, touchpad and keyboard pages; after hm.kdl, so they win
    "layout"
    "windowrules"
    "wpblur"
  ];
  xdg.configFile.niri-config-dms.text = lib.mkBefore ''
    include optional=true "dms/outputs.kdl"
  '';

  #--- For Omni Settings' Side Rail page: the shared apps and the changes applied
  xdg.configFile."omni-settings/side-rail.json".text = builtins.toJSON {
    inherit (sideRail) geometry shared;
    changes = user.sideRail;
  };

  home.file = {
    #--- Niri KDL configuration files (auto-generated by home-manager)
    ".config/niri/dms/alttab.kdl" = {
      text = "// Alt-Tab configuration (DMS)\n";
    };

    ".config/niri/dms/layout.kdl" = {
      text = "// Layout configuration (DMS)\n";
    };

    ".config/niri/dms/wpblur.kdl" = {
      # Blur and translucency come from the Mod+Y preset (core/blur-presets.nix)
      text = ''
        include optional=true "${config.xdg.configHome}/niri/dms/blur-preset.kdl"
        include optional=true "${config.xdg.configHome}/niri/dms/opacity-extra.kdl"
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
    ../../../dms-polkit
    {
      # Not DMS's own programs.dank-material-shell.settings, which would write
      # the same file
      options.dms.extraSettings = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Keys merged over settings.json on one machine.";
      };
      options.dms.pluginSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = {};
        description = "Settings per plugin name, merged into plugin_settings.json.";
      };
    }
  ];
}
