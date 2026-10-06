#=====================================================================#
# SYNCTHING
#=====================================================================#
#- Peer-to-peer file sync, run as the main user. Web UI at
#- http://127.0.0.1:8384, where devices and folders are paired.
{username, ...}: {
  #--------------------------------------------------------------------#
  #-- Syncthing Service
  #--------------------------------------------------------------------#
  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    openDefaultPorts = true; # TCP/UDP 22000 sync, UDP 21027 LAN discovery

    #--- Nothing is declared in Nix, so these must stay false or every
    #--- restart deletes the devices and folders paired in the web UI
    overrideDevices = false;
    overrideFolders = false;

    #--- GUI user, password and API key stay in the web UI, out of the repo
    settings = {
      options = {
        natEnabled = false; # UPnP would announce the home IP past Mullvad
        globalAnnounceEnabled = false; # devices only find each other on the LAN
        localAnnounceEnabled = true;
        relaysEnabled = true;
        urAccepted = -1; # usage reporting declined
        startBrowser = false;
      };
      gui = {
        useTLS = false;
        theme = "dark";
      };
    };
  };
}
