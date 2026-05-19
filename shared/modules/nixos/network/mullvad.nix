#=====================================================================#
# MULLVAD VPN CONFIGURATION
#=====================================================================#
{
  pkgs,
  ...
}:
{
  #--------------------------------------------------------------------#
  #-- Mullvad VPN Service
  #--------------------------------------------------------------------#
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  #--------------------------------------------------------------------#
  #-- Mullvad GUI Dependencies
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    libglvnd # OpenGL library (required for Mullvad VPN GUI)
  ];

  #--------------------------------------------------------------------#
  #-- DNS Configuration with VPN
  #--------------------------------------------------------------------#
  #--- DNS flow (automatic priority):
  #--- 1. VPN connected: Mullvad DNS (10.64.0.1) via wg0-mullvad interface
  #--- 2. VPN disconnected: DHCP DNS from local gateway
  #--- 3. Fallback: Public DNS (Cloudflare, Google) if all else fails
  #--- Benefits:
  #---   - Mullvad DNS: DNS-over-TLS encryption + DNSSEC validation
  #---   - Automatic failover when VPN connects/disconnects
  #---   - VPN-aware DNS routing
  #--- Verify DNS leak protection: https://mullvad.net/check
}
