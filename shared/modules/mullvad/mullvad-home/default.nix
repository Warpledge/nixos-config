#=====================================================================#
# MULLVAD HOME MANAGER MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  imports =
    [
      ./gui.nix
    ]
    #--- Split tunnel (controlled by hostConfig.mullvad.splitTunnel)
    ++ lib.optionals ((hostConfig.mullvad.splitTunnel or []) != []) [./split-tunnel.nix];
}
