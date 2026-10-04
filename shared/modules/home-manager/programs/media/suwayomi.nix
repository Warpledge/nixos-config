#=====================================================================#
# SUWAYOMI APP WINDOW
#=====================================================================#
#- Launcher entry that opens the Suwayomi web UI (server in
#- nixos/services/suwayomi.nix) as a Helium app window, with no tabs or
#- address bar. Needs browsers.helium.
#-
#- The launcher asks for a password first. Its hash lives outside the
#- repo, set with suwayomi-set-password. The server itself stays open
#- on localhost to anything else.
{
  pkgs,
  osConfig,
  ...
}: let
  server = osConfig.services.suwayomi-server;

  hashFile = "$HOME/.local/share/suwayomi-lock/password";

  #--- sha512-crypt via openssl; the password goes over stdin, not argv
  hashCmd = ''printf '%s' "$1" | openssl passwd -6 -salt "$2" -stdin'';

  setPassword = pkgs.writeShellApplication {
    name = "suwayomi-set-password";
    runtimeInputs = [pkgs.openssl];
    text = ''
      read -rsp "New Suwayomi password: " pw; echo
      read -rsp "Repeat: " pw2; echo
      if [ -z "$pw" ] || [ "$pw" != "$pw2" ]; then
        echo "Passwords empty or do not match" >&2
        exit 1
      fi
      hash() { ${hashCmd}; }
      mkdir -p "$(dirname "${hashFile}")"
      (umask 077 && hash "$pw" "$(openssl rand -hex 8)" > "${hashFile}")
      echo "Saved."
    '';
  };

  launcher = pkgs.writeShellApplication {
    name = "suwayomi";
    runtimeInputs = [pkgs.openssl pkgs.zenity];
    text = ''
      if [ ! -f "${hashFile}" ]; then
        zenity --error --text="No Suwayomi password yet. Run suwayomi-set-password in a terminal."
        exit 1
      fi
      stored=$(cat "${hashFile}")
      salt=$(cut -d'$' -f3 <<< "$stored")
      pw=$(zenity --password --title=Suwayomi) || exit 1
      hash() { ${hashCmd}; }
      if [ "$(hash "$pw" "$salt")" != "$stored" ]; then
        zenity --error --text="Wrong password."
        exit 1
      fi
      exec helium --app=http://localhost:${toString server.settings.server.port}
    '';
  };

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
    exec = "${launcher}/bin/suwayomi";
    icon = "${icon}";
    terminal = false;
    categories = ["Graphics" "Viewer"];
  };

  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [setPassword];
}
