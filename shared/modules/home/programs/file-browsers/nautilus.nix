#=====================================================================#
# NAUTILUS FILE BROWSER CONFIGURATION
#=====================================================================#
{
  pkgs,
  username,
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
    "file:///home/${username}/Downloads Downloads"
    "file:///home/${username}/Documents Documents"
    "file:///home/${username}/Pictures Pictures"
    "file:///home/${username}/Videos Videos"
    "file:///home/${username}/Games Games"
    "file:///home/${username}/.local/share Local"
    "file:///home/${username}/.local/share/Steam/steamapps/common Steam"
    "file:///home/${username}/.local/share/Terraria/tModLoader tModLoader"
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
