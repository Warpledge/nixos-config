#=====================================================================#
# DUX FILES (DUX-FILES) FILE BROWSER CONFIGURATION
#=====================================================================#
{config, lib, pkgs, inputs, ...}: {
  #--------------------------------------------------------------------#
  #-- Packages & Modules
  #--------------------------------------------------------------------#

  imports = [
    inputs.dux-files.homeModules.dux-files
  ];

  programs.dux-files = {
    enable = true;

    # Keep a resident instance so windows open fast and the portal answers at once
    systemd.enable = true;
  };

  #--------------------------------------------------------------------#
  #-- Bookmarks
  #--------------------------------------------------------------------#

  gtk.gtk3.bookmarks = [
    "file://${config.home.homeDirectory}/Downloads Downloads"
    "file://${config.home.homeDirectory}/Documents Documents"
    "file://${config.home.homeDirectory}/Pictures Pictures"
    "file://${config.home.homeDirectory}/Videos Videos"
    "file://${config.home.homeDirectory}/Games Games"
    "file://${config.home.homeDirectory}/.local/share Local"
    "file://${config.home.homeDirectory}/.local/share/Steam/steamapps/common Steam"
    "file://${config.home.homeDirectory}/.local/share/Terraria/tModLoader tModLoader"
  ];
}
