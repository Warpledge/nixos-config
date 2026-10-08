#=====================================================================#
# NETWORKING (DIAGNOSTIC TOOLS + MODULE IMPORTS)
#=====================================================================#
{pkgs, ...}: {
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
  imports = [
    ./blockers.nix
    ./dns.nix
    ./firewall.nix
    ./networkmanager.nix
  ];
}
