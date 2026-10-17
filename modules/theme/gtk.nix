#=====================================================================#
# GTK THEME & ICON CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  pkgs,
  machine,
  ...
}: {
  #--- Every user on the machine
  home-manager.users =
    lib.mapAttrs (_: _: {
      #--------------------------------------------------------------------#
      #-- Icon Theme (for Quickshell & other apps)
      #--------------------------------------------------------------------#
      # Papirus-Dark with Mauve folders comes from catppuccin's gtk.icon port
      gtk.enable = true;

      #--------------------------------------------------------------------#
      #-- Icon Theme Packages
      #--------------------------------------------------------------------#
      home.packages = with pkgs; [
        adwaita-icon-theme
      ];

      #--------------------------------------------------------------------#
      #-- Icon Theme Symlink for Quickshell & Shells
      #--------------------------------------------------------------------#
      # Write index.theme instead of symlinking whole dir — allows the Stylix
      # cursor theme to be found by Xwayland alongside Papirus-Dark icons
      home.file.".icons/default/index.theme".text = ''
        [Icon Theme]
        Name=Default
        Inherits=${config.stylix.cursor.name},Papirus-Dark,hicolor
      '';
    })
    machine.users;
}
