#=====================================================================#
# NIRI TRANSLUCENT APPS
#=====================================================================#
# Windows that get the opacity rule (rules.nix) and the blur preset's opacity
# (blur-presets.nix), so the wallpaper shows through them.
[
  {app-id = "kitty";}
  {app-id = "com.mitchellh.ghostty";}
  {app-id = "dev.zed.Zed";}
  {app-id = "org.gnome.Nautilus";}
  {app-id = "org.gnome.FileRoller";}
  {app-id = "org.kde.ark";}
  {app-id = "org.kde.dolphin";}
  {app-id = "dev.duxlabs.files";}
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
  # Floating = Quick Entry, which would otherwise show the wallpaper through its card
  {
    app-id = "^com\\.anthropic\\.Claude$";
    is-floating = false;
  }
  {app-id = "^ai\\.opencode\\.desktop$";}
  # DMS's own windows: Settings, System Monitor, Notepad, Keybinds and the rest
  {app-id = "^dev\\.duxlabs\\.shell$";}
  {app-id = "Revolt";}
  {app-id = "discord";}
  {app-id = "(?i)goofcord$";}
  {app-id = "(?i)^vesktop$";}
  {app-id = "heroic";}
  {app-id = "spotify";}
  {app-id = "org.prismlauncher.PrismLauncher";}
  {app-id = "^org\\.gnome\\.Resources$";}
  {app-id = "^dev\\.nixosconfig\\.Settings$";}
  {app-id = "^com\\.github\\.tchx84\\.Flatseal$";}
  {title = "Volume Control";}
  {title = "Open File";}
  {title = "File Upload";}
  {title = "branchdialog";}
  {title = "Confirm to replace files";}
]
