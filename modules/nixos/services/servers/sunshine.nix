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
    openFirewall = true; # TCP 47984, 47989-47990, 48010; UDP 47998-48000, 48002, 48010
    capSysAdmin = true; # KMS capture; niri lacks the wlr-export-dmabuf protocol
  };
}
