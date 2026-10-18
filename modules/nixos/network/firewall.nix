#=====================================================================#
# FIREWALL
#=====================================================================#
{machine, ...}: {
  #--------------------------------------------------------------------#
  #-- Firewall Configuration
  #--------------------------------------------------------------------#
  networking.firewall = {
    enable = true;
    #--- The machine's settings.nix (firewall.*); SSH (services/ssh.nix),
    #--- Minecraft (machines/legion) and Steam open their own
    allowedTCPPorts = machine.firewall.openTCPPorts;
    allowedUDPPorts = machine.firewall.openUDPPorts;
    #--- Ephemeral ports (49152-65535) for P2P game traffic handled by NAT
  };
}
