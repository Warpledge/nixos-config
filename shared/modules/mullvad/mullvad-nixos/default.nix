#=====================================================================#
# MULLVAD NIXOS MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  imports =
    [
      ./daemon.nix
    ]
    #--- Split tunnel (controlled by hostConfig.mullvad.splitTunnel)
    ++ lib.optionals ((hostConfig.mullvad.splitTunnel or []) != []) [./split-tunnel.nix];
}
