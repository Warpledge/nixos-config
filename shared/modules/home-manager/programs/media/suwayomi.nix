#=====================================================================#
# SUWAYOMI APP WINDOW
#=====================================================================#
#- Launcher entry that opens the Suwayomi web UI (server in
#- nixos/services/suwayomi.nix) as a Helium app window, with no tabs or
#- address bar. Needs browsers.helium.
{
  pkgs,
  osConfig,
  ...
}: let
  server = osConfig.services.suwayomi-server;

  #--- Logo shipped inside the server jar, so it tracks the pinned version
  icon = pkgs.runCommand "suwayomi-icon.png" {nativeBuildInputs = [pkgs.unzip];} ''
    unzip -p ${server.package.src} icon/faviconlogo.png > $out
  '';
in {
  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.suwayomi = {
    name = "Suwayomi";
    comment = "Local manga reader";
    exec = "helium --app=http://localhost:${toString server.settings.server.port}";
    icon = "${icon}";
    terminal = false;
    categories = ["Graphics" "Viewer"];
  };
}
