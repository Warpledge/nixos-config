#=====================================================================#
# SUNSHINE - GAME STREAMING HOST
#=====================================================================#
#- Streams the desktop and games to Moonlight on the LAN. Set the web UI login
#- at https://localhost:47990 right after the first rebuild, then pair clients there.
{
  #--------------------------------------------------------------------#
  #-- Sunshine Service
  #--------------------------------------------------------------------#
  #--- The module also enables uinput, plus Avahi so clients can find the host
  services.sunshine = {
    enable = true;
    openFirewall = false; # Would also open 47990, the web UI; stream ports below
    capSysAdmin = true; # KMS capture; niri lacks the wlr-export-dmabuf protocol
  };

  #--- The module's openFirewall list without 47990, so the web UI stays local
  networking.firewall = {
    allowedTCPPorts = [47984 47989 48010];
    allowedUDPPorts = [47998 47999 48000 48002 48010];
  };
}
