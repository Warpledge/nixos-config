#=====================================================================#
# GTK THEME & ICON CONFIGURATION
#=====================================================================#
{
  pkgs,
  username,
  ...
}: {
  home-manager.users.${username} = {config, ...}: {
    #--------------------------------------------------------------------#
    #-- Icon Theme (for Quickshell & other apps)
    #--------------------------------------------------------------------#
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4.theme = config.gtk.theme; # keep legacy stylix-managed theme behavior
    };

    #--------------------------------------------------------------------#
    #-- Icon Theme Packages
    #--------------------------------------------------------------------#
    home.packages = with pkgs; [
      papirus-icon-theme
      papirus-folders
      adwaita-icon-theme
    ];

    #--------------------------------------------------------------------#
    #-- Icon Theme Symlink for Quickshell & Shells
    #--------------------------------------------------------------------#
    # Write index.theme instead of symlinking whole dir — allows cursor theme
    # (Bibata-Modern-Ice) to be found by Xwayland alongside Papirus-Dark icons
    home.file.".icons/default/index.theme".text = ''
      [Icon Theme]
      Name=Default
      Inherits=Bibata-Modern-Ice,Papirus-Dark,hicolor
    '';
  };
}
