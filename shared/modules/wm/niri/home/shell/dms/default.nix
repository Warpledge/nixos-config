{
  inputs,
  lib,
  hostname,
  hostConfig,
  ...
}: {
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
    # Any `settings` here makes plugin_settings.json a read-only store link, so
    # changes in a plugin's settings page no longer save: mirror them back here.
    plugins = {
      # The variant pins the desktop's GPU by PCI address; the bar widget id
      # in settings.json (amdGpuMonitor:<id>) must match it.
      amdGpuMonitor = {
        enable = hostname == "desktop";
        settings = {
          popoutStyle = "default";
          minimumWidth = true;
          variants = [
            {
              id = "variant_1791177076814";
              name = "AMD Radeon RX 9070 XT";
              originalName = "AMD Radeon RX 9070 XT";
              description = "Monitor your discrete AMD Radeon RX 9070 XT";
              gpuPci = "0000:09:00.0";
              gpuType = "dGPU";
              icon = "memory";
            }
          ];
        };
      };

      # The plugin stores its options as strings, booleans included.
      aiOverviewControl = {
        enable = hostConfig.claude.enable;
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
    enableCalendarEvents = false; # Calendar integration (khal) - disabled: khal-0.13.0 broken in nixpkgs
    enableClipboardPaste = true; # Clipboard pasting via wtype
  };

  #--------------------------------------------------------------------#
  #-- DankMaterialShell NIRI KEYBINDS --#
  #--------------------------------------------------------------------#
  programs.niri.settings.binds = let
    dms = action: ["dms" "ipc" "call"] ++ (lib.splitString " " action);
  in {
    #--- DankMaterialShell Controls
    "Mod+A".action.spawn = dms "spotlight toggle"; # Application Launcher
    "Mod+V".action.spawn = dms "clipboard toggle"; # Clipboard Manager
    "Mod+P".action.spawn = dms "processlist toggle"; # Task Manager
    "Mod+Comma".action.spawn = dms "settings toggle"; # Settings
    "Mod+N".action.spawn = dms "notepad toggle"; # Notepad
    "Mod+K".action.spawn = dms "powermenu toggle"; # Power Menu
    "Mod+W".action.spawn = dms "dankdash wallpaper"; # Browse Wallpapers
    "Mod+Shift+N".action.spawn = dms "night toggle"; # Night Mode Toggle
    "Mod+L".action.spawn = dms "lock lock"; # Toggle lock screen
    "Mod+I".action.spawn = dms "inhibit toggle"; # Toggle idle inhibit
    "Mod+slash".action.spawn = dms "keybinds toggle niri"; # Show Keybind Cheatsheet
    "Mod+R".action.spawn = ["dms" "restart"]; # Restart DMS

    #--- Quick Capture: screenshots open in its editor
    "Print".action.spawn = dms "quickCapture screenshot region edit"; # Region Select
    "Mod+Print".action.spawn = dms "quickCapture screenshot window edit"; # Focused Window
    "Mod+Shift+Print".action.spawn = dms "quickCapture screenshot full edit"; # Focused Output
    "Ctrl+Print".action.spawn = dms "quickCapture screenshot all edit"; # All Outputs
    "Mod+Ctrl+Print".action.spawn = dms "quickCapture screenshot scroll edit"; # Scrolling Capture

    #--- Quick Capture: recording
    # portal only: the gpu-screen-recorder screen/region modes capture via KMS,
    # which bypasses niri's block-out-from rules.
    "Mod+End".action.spawn = dms "quickCapture recordToggle portal"; # Toggle Recording

    #--- Audio controls
    "XF86AudioRaiseVolume".action.spawn = dms "audio increment 3"; # Volume Up
    "XF86AudioLowerVolume".action.spawn = dms "audio decrement 3"; # Volume Down
    "XF86AudioMute".action.spawn = dms "audio mute"; # Mute Audio
    "XF86AudioMicMute".action.spawn = dms "audio micmute"; # Mute Microphone

    #--- Brightness controls
    "XF86MonBrightnessUp".action.spawn = dms "brightness increment 5"; # Brightness Up
    "XF86MonBrightnessDown".action.spawn = dms "brightness decrement 5"; # Brightness Down
  };

  #--------------------------------------------------------------------#
  #-- DECLARATIVE DankMaterialShell SETTINGS --#
  #--------------------------------------------------------------------#
  home.file = {
    #--- DMS Main Settings
    # Read-only store symlink: anything DMS rewrites at runtime must be baked
    # into settings.json, or the save fails on every start. Connected frame mode
    # is one such rewriter — it forces squareCorners and shadowIntensity off.
    ".config/DankMaterialShell/settings.json" = {
      text = builtins.toJSON (lib.importJSON ./settings.json);
    };

    #--- DMS Clipboard Settings
    ".config/DankMaterialShell/clsettings.json" = {
      source = ./clsettings.json;
    };

    ".config/DankMaterialShell/cheatsheets/niri-dms.json" = {
      source = ./niri-cheatsheet.json;
    };

    #--- Niri KDL configuration files (auto-generated by home-manager)
    ".config/niri/dms/binds.kdl" = {
      text = "// DMS keybinds are configured via niri settings\n";
    };

    ".config/niri/dms/colors.kdl" = {
      text = "// Colors configured via Catppuccin theme\n";
    };

    ".config/niri/dms/outputs.kdl" = {
      text = "// Outputs configured in niri settings\n";
    };

    ".config/niri/dms/alttab.kdl" = {
      text = "// Alt-Tab configuration (DMS)\n";
    };

    ".config/niri/dms/layout.kdl" = {
      text = "// Layout configuration (DMS)\n";
    };

    ".config/niri/dms/wpblur.kdl" = {
      text = ''
        // Wallpaper blur configuration (DMS)
        blur {
            passes 4
            offset 4.0
            noise 0.0
            saturation 1.2
        }

        // Catch-all: every window gets the wallpaper blur behind it.
        // Excluded app-ids opt out entirely (Steam renders its own opaque chrome).
        window-rule {
            exclude app-id="^steam$"

            background-effect {
                blur true
                xray true
            }
        }
      '';
    };
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.dms-plugin-registry.homeModules.default
  ];
}
