#=====================================================================#
# NIRI WINDOW RULES
#=====================================================================#
let
  windowRules = [
    #--- Privacy Rules (blocked from both screenshots and screen recording)
    {
      matches = [
        {app-id = "org.gnome.seahorse.Application";}
        {app-id = "bitwarden";}
        {app-id = "cohesion";}
        {app-id = "Mullvad VPN";}
        {app-id = "Mullvad Browser";}
      ];
      block-out-from = "screen-capture";
    }

    #--- Opacity Rules (enables blur to show through)
    {
      matches = [
        {app-id = "kitty";}
        {app-id = "com.mitchellh.ghostty";}
        {app-id = "dev.zed.Zed";}
        {app-id = "org.gnome.Nautilus";}
        {app-id = "org.gnome.FileRoller";}
        {app-id = "org.kde.dolphin";}
        {app-id = "thunar";}
        {app-id = "org.pulseaudio.pavucontrol";}
        {app-id = "pavucontrol";}
        {app-id = "nm-connection-editor";}
        {app-id = "org.gnome.Calculator";}
        {app-id = "guifetch";}
        {app-id = "blueberry.py";}
        {app-id = "Zotero";}
        {app-id = "io.github.alainm23.planify";}
        {app-id = "org.quickshell";}
        {app-id = "Revolt";}
        {app-id = "discord";}
        {app-id = "vesktop";}
        {app-id = "heroic";}
        {app-id = "spotify";}
        {app-id = "org.prismlauncher.PrismLauncher";}
        {title = "Volume Control";}
        {title = "Open File";}
        {title = "File Upload";}
        {title = "branchdialog";}
        {title = "Confirm to replace files";}
      ];
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

    #--- Full Width Rules
    {
      matches = [
        {app-id = "zen-beta";}
        {app-id = "helium";}
      ];
      default-column-width = {proportion = 1.0;};
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
        active.color = "#cba6f7"; # Catppuccin Mocha Mauve (Mauve)3
        inactive.color = "#1e1e2e"; # Dark base for inactive windows
      };
      border = {
        inactive.color = "#1e1e2e"; # Same dark base for border inactive
      };
      shadow = {
        color = "#1e1e2e70"; # Transparent dark shadow
      };
      tab-indicator = {
        active.color = "#cba6f7";
        inactive.color = "#1e1e2e";
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
  ];
in {
  programs.niri.settings = {
    window-rules = windowRules;
    layer-rules = [
      {
        matches = [{namespace = "^swww$";}];
        place-within-backdrop = true;
      }
      {
        matches = [{namespace = "^dms:clipboard$";}];
        block-out-from = "screen-capture";
      }
    ];
  };
}
