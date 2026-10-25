#=====================================================================#
# NETWORKING (DIAGNOSTIC TOOLS + MODULE IMPORTS)
#=====================================================================#
{
  lib,
  pkgs,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Diagnostic Tools
  #--------------------------------------------------------------------#
  boot.kernelModules = ["af_packet"]; # Packet capturing/injection support
  environment.systemPackages = with pkgs; [
    bind.dnsutils # DNS utilities
    mtr # Network diagnostics tool
    tcpdump # Packet analyzer
    traceroute # Network trace tool
  ];

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./dns.nix
      ./firewall.nix
      ./networkmanager.nix
    ]
    #--- Hosts blocklist (controlled by machine settings)
    ++ lib.optionals machine.blocklist.enable [./blockers.nix]
    ++ lib.optionals machine.smb.enable [./smb.nix];
}
