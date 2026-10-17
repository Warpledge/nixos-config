#=====================================================================#
# NAUTILUS FILE BROWSER CONFIGURATION
#=====================================================================#
{
  config,
  pkgs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Packages & Bookmarks
  #--------------------------------------------------------------------#

  home.packages = with pkgs; [
    nautilus
    sushi
  ];

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

  #--------------------------------------------------------------------#
  #-- Preferences
  #--------------------------------------------------------------------#
  dconf.settings = {
    "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
    "org/gnome/nautilus/list-view" = {
      use-tree-view = true;
      default-zoom-level = "small";
    };
  };
}
