#=====================================================================#
# GNOME EXTENSIONS CONFIGURATION
#=====================================================================#
{lib, ...}: {
  imports = [
    # ./forge
    ./appindicator.nix
    ./auto-move-windows.nix
    ./astra-monitor.nix
    ./blur-my-shell.nix
    ./caffeine.nix
    ./dash-to-panel.nix
    ./date-menu-formatter.nix
    ./gamemode.nix
    ./gnome-ui-tune.nix
    ./space-bar.nix
  ];

  dconf.settings = with lib.gvariant; {
    #--------------------------------------------------------------------#
    #-- Disabled Extensions
    #--------------------------------------------------------------------#
    "org/gnome/shell".disabled-extensions = [
      "apps-menu@gnome-shell-extensions.gcampax.github.com"
      "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
      "light-style@gnome-shell-extensions.gcampax.github.com"
      "native-window-placement@gnome-shell-extensions.gcampax.github.com"
      "places-menu@gnome-shell-extensions.gcampax.github.com"
      "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
      "user-theme@gnome-shell-extensions.gcampax.github.com"
      "window-list@gnome-shell-extensions.gcampax.github.com"
      "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
      "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
      "forge@jmmaranan.com"
    ];
  };
}
