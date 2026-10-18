#=====================================================================#
# NIRI WINDOW RULES
#=====================================================================#
{
  config,
  lib,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;

  windowRules = [
    #--- Privacy Rules (blocked from both screenshots and screen recording)
    {
      matches = [
        {app-id = "org.gnome.seahorse.Application";}
        {app-id = "bitwarden";}
        {
          app-id = "^zen-beta$";
          title = "^Extension: \\(Bitwarden";
        } # Bitwarden extension popup (Zen)
        {app-id = "mullvad-vpn";}
        {app-id = "Mullvad Browser";}
        {app-id = "^helium$";}
        {app-id = "^chrome-localhost__-Default$";} # Suwayomi (Helium app window)
        # Syncthing (Helium app window)
        {app-id = "^chrome-127\\.0\\.0\\.1__index\\.html-Default$";}
        {app-id = "^moku$";}
        {app-id = "^boorusama$";}
        {app-id = "^thunderbird$";}
        {app-id = "^md\\.obsidian\\.Obsidian$";}
        {app-id = "^homebank$";}
        {app-id = "(?i)goofcord$";}
        {app-id = "^mpv$";}
      ];
      block-out-from = "screen-capture";
    }

    #--- Opacity Rules (enables blur to show through)
    # Fallback; the active blur preset (blur-presets.nix) overrides the opacity
    {
      matches = import ./translucent-apps.nix;
      opacity = 0.8;
    }

    #--- Prevent Auto-Maximize
    {
      matches = [
      ];
      open-maximized = false;
    }

    #--- Fullscreen Rules
    {
      matches = [
        {app-id = "^Minecraft";}
      ];
      open-fullscreen = true;
    }

    #--- Variable Refresh Rate (outputs set "on-demand" in core/monitors.nix)
    #--- Proton app-ids: <game>.exe on native Wayland, steam_app_<id> on X11
    {
      matches = [
        {app-id = "^gamescope$";}
        {app-id = "^steam_app_";}
        {app-id = "\\.exe$";}
        {app-id = "^Minecraft";}
      ];
      variable-refresh-rate = true;
    }

    #--- Full Width Rules
    {
      matches = [
        {app-id = "zen-beta";}
        {app-id = "helium";}
        {app-id = "freetube";}
      ];
      default-column-width = {proportion = 1.0;};
    }

    #--- Open Unfocused
    #--- Keeps youtube-dispatch link handoffs in the background; each one is a
    #--- new window (openDeepLinksInNewWindow). Outranks the activation token.
    {
      matches = [
        {app-id = "freetube";}
      ];
      open-focused = false;
    }

    #--- Floating Rules
    #--- ProtonUp-Qt (Wine/Proton Installer)
    {
      matches = [
        {app-id = "net.davidotek.pupgui2";}
      ];
      open-floating = true;
      open-focused = true;
      default-column-width = {fixed = 600;};
      default-window-height = {fixed = 600;};
      default-floating-position = {
        x = 0;
        y = 50;
        relative-to = "top";
      };
    }

    #--- Steam secondary windows (Friends List, Settings, game properties)
    #--- Main library window stays tiled; no position set, so niri centers them.
    {
      matches = [{app-id = "^steam$";}];
      excludes = [{title = "^Steam$";}];
      open-floating = true;
    }

    #--- Guitar Pro 8 Fretboard panel
    {
      matches = [
        {title = "Fretboard - Guitar Pro 8";}
      ];
      open-floating = true;
      default-column-width = {fixed = 1687;};
      default-window-height = {fixed = 222;};
    }

    #--- Bitwarden extension popout (Zen PIN unlock); outranks the zen-beta
    #--- full-width rule
    {
      matches = [
        {
          app-id = "^zen-beta$";
          title = "^Extension: \\(Bitwarden";
        }
      ];
      open-floating = true;
      default-column-width = {fixed = 553;};
      default-window-height = {fixed = 762;};
    }

    #--- TONE3000 (JUCE standalone): fixed-size UI that letterboxes when tiled.
    #--- No size set, so the client keeps its own preferred geometry.
    {
      matches = [
        {app-id = "^TONE3000$";}
      ];
      open-floating = true;
      open-focused = true;
    }

    #--- Resources task manager (Ctrl+Alt+Delete); floating stays above tiled
    #--- windows, and with no position set niri centers it. Its maximize
    #--- request is refused in the raw KDL at the bottom of this file
    {
      matches = [{app-id = "^org\\.gnome\\.Resources$";}];
      open-floating = true;
      default-column-width = {proportion = 0.6;};
      default-window-height = {proportion = 0.7;};
    }

    #--- NixOS Settings (Mod+Shift+C): floating and centered, as wide as its
    #--- pages' fixed content width
    {
      matches = [{app-id = "^dev\\.nixosconfig\\.Settings$";}];
      open-floating = true;
      default-column-width = {fixed = 1080;};
      default-window-height = {proportion = 0.88;};
    }

    #--- Flatseal: floating and centered, sized like NixOS Settings
    {
      matches = [{app-id = "^com\\.github\\.tchx84\\.Flatseal$";}];
      open-floating = true;
      default-column-width = {fixed = 1080;};
      default-window-height = {proportion = 0.88;};
    }

    #--- Calculator
    {
      matches = [
        {app-id = "org.gnome.Calculator";}
      ];
      open-floating = true;
    }

    #--- Wine installers and dialogs
    {
      matches = [
        {app-id = "wineboot.exe";}
        {app-id = "control.exe";}
        {title = "Wine";}
        {title = "Wine Mono Installer";}
        {title = "Wine Gecko Installer";}
      ];
      open-floating = true;
      open-focused = true;
    }

    #--- Wine WebView2 (embedded login panels, e.g. Morimens)
    #--- clip-to-geometry + draw-border-with-background=false breaks rendering
    {
      matches = [{app-id = "msedgewebview2.exe";}];
      clip-to-geometry = false;
      draw-border-with-background = true;
    }

    #--- Audio/Media Applications
    {
      matches = [
        {app-id = "pavucontrol";}
        {app-id = "pavucontrol-qt";}
        {app-id = "com.saivert.pwvucontrol";}
        {app-id = "io.github.fsobolev.Cavalier";}
        {app-id = "org.gnome.Loupe";}

        #--- System Dialogs and Utilities
        {app-id = "dialog";}
        {app-id = "popup";}
        {app-id = "task_dialog";}
        {app-id = "gcr-prompter";}
        {app-id = "file-roller";}
        {app-id = "org.gnome.FileRoller";}
        {app-id = "org.kde.ark";}
        {app-id = "nm-connection-editor";}
        {app-id = "blueman-manager";}
        {app-id = "xdg-desktop-portal-gtk";}
        {app-id = "org.kde.polkit-kde-authentication-agent-1";}
        {app-id = "pinentry";}

        #--- File Operation and Status Dialogs
        {title = "Progress";}
        {title = "File Operations";}
        {title = "Copying";}
        {title = "Moving";}
        {title = "Properties";}
        {title = "Downloads";}
        {title = "file progress";}

        #--- Alert and Confirmation Dialogs
        {title = "Confirm";}
        {title = "Authentication Required";}
        {title = "Notice";}
        {title = "Warning";}
        {title = "Error";}
      ];
      open-floating = true;
    }

    #--------------------------------------------------------------------#
    #-- GLOBAL WINDOW STYLING --#
    #--------------------------------------------------------------------#

    {
      geometry-corner-radius = let
        radius = 12.0;
      in {
        bottom-left = radius;
        bottom-right = radius;
        top-left = radius;
        top-right = radius;
      };
      clip-to-geometry = true;
      draw-border-with-background = false;
    }
    {
      matches = [
        {is-floating = true;}
      ];
      shadow.enable = true;
    }
    {
      matches = [
        {
          is-window-cast-target = true;
        }
      ];
      focus-ring = {
        active.color = colors.base0E; # Mauve
        inactive.color = colors.base00; # Dark base for inactive windows
      };
      border = {
        inactive.color = colors.base00; # Same dark base for border inactive
      };
      shadow = {
        color = "${colors.base00}70"; # Transparent dark shadow
      };
      tab-indicator = {
        active.color = colors.base0E;
        inactive.color = colors.base00;
      };
    }

    #--------------------------------------------------------------------#
    #-- PICTURE-IN-PICTURE --#
    #--------------------------------------------------------------------#

    {
      matches = [
        {
          app-id = "firefox";
          title = "Picture-in-Picture";
        }
      ];
      open-floating = true;
      default-floating-position = {
        x = 32;
        y = 32;
        relative-to = "bottom-right";
      };
      default-column-width = {fixed = 480;};
      default-window-height = {fixed = 270;};
    }
    {
      matches = [
        {
          app-id = "zen";
          title = "Picture-in-Picture";
        }
      ];
      open-floating = true;
      default-floating-position = {
        x = 32;
        y = 32;
        relative-to = "bottom-right";
      };
      default-column-width = {fixed = 480;};
      default-window-height = {fixed = 270;};
    }
    {
      matches = [{title = "Picture in picture";}];
      open-floating = true;
      default-floating-position = {
        x = 32;
        y = 32;
        relative-to = "bottom-right";
      };
    }
    {
      matches = [{title = "Discord Popout";}];
      open-floating = true;
      default-floating-position = {
        x = 32;
        y = 32;
        relative-to = "bottom-right";
      };
    }

    #--------------------------------------------------------------------#
    #-- XWAYLAND RESIZE FILL --#
    #--------------------------------------------------------------------#

    #--- XWayland has no synchronized-resize handshake, so an interactive
    #--- resize exposes frame area the client has not repainted yet. Drawing
    #--- the border as a solid rect fills it instead of showing the backdrop.
    #--- Must stay after the global styling rule, which sets this false for all.
    {
      matches = [{app-id = "^steam$";}];
      draw-border-with-background = true;
    }
  ];
in {
  programs.niri.settings = {
    window-rules = windowRules;
    layer-rules = [
      {
        # DMS's blurred wallpaper copy (blurredWallpaperLayer in dms/settings.json),
        # or linux-wallpaperengine when wallpaper = "engine" replaces it
        matches = [
          {namespace = "^dms:blurwallpaper$";}
          {namespace = "^linux-wallpaperengine$";}
        ];
        place-within-backdrop = true;
      }
      {
        matches = [
          {namespace = "^dms:clipboard$";}
          {namespace = "^dms:notification-popup$";}
          # ClipBoard+ panel, emoji picker and item context menu
          {namespace = "^dms-clipboardPlus-";}
          {namespace = "^dms-selection-menu-";}
        ];
        block-out-from = "screen-capture";
      }
    ];
  };

  #--------------------------------------------------------------------#
  #-- Raw KDL Rules
  #--------------------------------------------------------------------#
  #- For rule options niri-flake doesn't expose yet, appended to the
  #- config.kdl DMS generates (a lines option, so definitions merge)
  xdg.configFile.niri-config-dms.text = lib.mkAfter ''
    window-rule {
        match app-id="^org\\.gnome\\.Resources$"
        open-maximized-to-edges false
    }
  '';
}
