#=====================================================================#
# MULLVAD VPN MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./daemon.nix
      ./gui.nix
    ]
    #--- Split tunnel (controlled by hostConfig.mullvad.splitTunnel)
    ++ lib.optionals ((hostConfig.mullvad.splitTunnel or []) != []) [./split-tunnel.nix];
}
