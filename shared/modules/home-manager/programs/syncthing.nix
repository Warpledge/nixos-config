#=====================================================================#
# SYNCTHING APP WINDOW
#=====================================================================#
#- Opens the Syncthing web UI (service in nixos/services/syncthing.nix)
#- as a Helium app window. Needs browsers.helium. Shares the stock entry's
#- name, so it replaces the one that opens the default browser.
{osConfig, ...}: {
  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.syncthing-ui = {
    name = "Syncthing";
    comment = "File synchronization";
    #--- /index.html keeps the app-id apart from Seanime's (same host, root path)
    exec = "helium --app=http://${osConfig.services.syncthing.guiAddress}/index.html";
    icon = "syncthing";
    terminal = false;
    categories = ["Network" "FileTransfer"];
  };
}
