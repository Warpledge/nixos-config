#=====================================================================#
# MULLVAD BROWSER CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Mullvad Browser Package
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    mullvad-browser # Privacy-focused browser with built-in Mullvad VPN integration
  ];
}
