#=====================================================================#
# FIREWALL
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Firewall Configuration
  #--------------------------------------------------------------------#
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # SSH (disabled in services.openssh, but port reserved)
      80 # HTTP
      443 # HTTPS
      25566 # Minecraft server
      7777 # Terraria server
      5555 # ADB port
    ];
    allowedUDPPorts = [
      27000
      27001
      27002
      27003
      27004
      27005
      27006
      27007
      27008
      27009
      27015
      27031
      27032
      27033
      27034
      27035
      27036
      4380 # Steam networking
    ];
    #--- Ephemeral ports (49152-65535) for P2P game traffic handled by NAT
  };
}
