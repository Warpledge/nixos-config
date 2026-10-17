#=====================================================================#
# MULLVAD VPN MODULE IMPORTS
#=====================================================================#
{
  lib,
  machine,
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
    #--- Split tunnel (controlled by mullvad.splitTunnel in machine settings)
    ++ lib.optionals (machine.mullvad.splitTunnel != []) [./split-tunnel.nix];
}
