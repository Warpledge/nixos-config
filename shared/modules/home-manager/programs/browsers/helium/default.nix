#=====================================================================#
# HELIUM BROWSER CONFIGURATION
#=====================================================================#

{inputs, ...}: {
  #--------------------------------------------------------------------#
  #-- Helium Browser Package
  #--------------------------------------------------------------------#
  home.packages = [
    inputs.helium.packages.x86_64-linux.helium
  ];

  #--------------------------------------------------------------------#
  #-- Helium Flags
  #--------------------------------------------------------------------#
  xdg.configFile."helium-flags.conf".text = ''
    #--- Wayland support
    --ozone-platform=wayland

    #--- Anti-fingerprinting
    --spoof-webgl-info

    #--- Anti-fingerprinting
    --spoof-webgl-info
  '';
}
