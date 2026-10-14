#=====================================================================#
# RESOURCES CONFIGURATION
#=====================================================================#
#- GNOME system and process monitor (GTK4/libadwaita)
{pkgs, ...}: {
  home.packages = [pkgs.resources];
}
