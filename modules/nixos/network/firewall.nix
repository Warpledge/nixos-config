#=====================================================================#
# FIREWALL
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Firewall Configuration
  #--------------------------------------------------------------------#
  networking.firewall = {
    enable = true;
    #--- SSH (services/ssh.nix), Minecraft (machines/laptop) and Steam open their own
    allowedTCPPorts = [
      7777 # Terraria server
    ];
    #--- Ephemeral ports (49152-65535) for P2P game traffic handled by NAT
  };
}
