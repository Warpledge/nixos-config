#=====================================================================#
# SYNCTHING
#=====================================================================#
#- Peer-to-peer file sync, run as the main user (mainUser in the machine's
#- settings.nix). Web UI at http://127.0.0.1:8384, where devices and folders
#- are paired.
{
  config,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Syncthing Service
  #--------------------------------------------------------------------#
  services.syncthing = {
    enable = true;
    user = machine.mainUser;
    dataDir = "/home/${machine.mainUser}";
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
        relaysEnabled = false; # unreachable without global discovery
        urAccepted = -1; # usage reporting declined
        crashReportingEnabled = false; # default on; panics go to crash.syncthing.net
        startBrowser = false;
      };
      gui = {
        useTLS = false;
        theme = "dark";
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- App Window (home-manager)
  #--------------------------------------------------------------------#
  #- Opens the web UI as a Helium app window. Shares
  #- the stock entry's name, so it replaces the one that opens the default browser.
  home-manager.users.${machine.mainUser}.xdg.desktopEntries.syncthing-ui = {
    name = "Syncthing";
    comment = "File synchronization";
    exec = "helium --app=http://${config.services.syncthing.guiAddress}/index.html";
    icon = "syncthing";
    terminal = false;
    categories = ["Network" "FileTransfer"];
  };
}
