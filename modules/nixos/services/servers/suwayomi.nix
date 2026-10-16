#=====================================================================#
# SUWAYOMI MANGA SERVER
#=====================================================================#
#- Local manga reader server. The web UI is at http://localhost:4567.
#-
#- The home-manager half adds a launcher entry that opens the web UI as a
#- Helium app window, with no tabs or address bar. Needs browsers.helium.
#- The launcher asks for a password first. Its hash lives outside the
#- repo, set with suwayomi-set-password. The server itself stays open
#- on localhost to anything else.
{
  config,
  pkgs,
  username,
  ...
}: let
  server = config.services.suwayomi-server;

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
  #-- Suwayomi Server
  #--------------------------------------------------------------------#
  services.suwayomi-server = {
    enable = true;

    #--- Pinned ahead of nixpkgs (2.1.1867)
    package = pkgs.suwayomi-server.overrideAttrs (finalAttrs: _: {
      version = "2.4.2366";
      src = pkgs.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${finalAttrs.version}/Suwayomi-Server-v${finalAttrs.version}.jar";
        hash = "sha256-r5/rIK+dfr6eMHaebG68f8erHERziNQuAoCx2l/ge/0=";
      };
    });

    settings.server = {
      ip = "127.0.0.1"; # Module default 0.0.0.0
      port = 4567; # Module default 8080 is taken by Steam's webhelper
    };
  };

  systemd.services.suwayomi-server.serviceConfig = {
    #--- Its scratch dir is /tmp/Tachidesk, which a user-run instance can own
    #--- first and lock the service out of
    PrivateTmp = true;

    #--- Sandboxing for the third-party extension code it runs. No
    #--- SystemCallFilter, MemoryDenyWriteExecute or RestrictNamespaces: KCEF's
    #--- Chromium sandbox needs chroot and user namespaces, the JIT needs W+X pages
    NoNewPrivileges = true;
    ProtectSystem = "strict"; # The module's StateDirectory stays writable
    ProtectHome = true;
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectProc = "invisible";
    RestrictSUIDSGID = true;
    RestrictRealtime = true;
    LockPersonality = true;
    CapabilityBoundingSet = "";
    RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
    SystemCallArchitectures = "native";
  };

  #--------------------------------------------------------------------#
  #-- App Window (home-manager)
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    xdg.desktopEntries.suwayomi = {
      name = "Suwayomi";
      comment = "Local manga reader";
      exec = "${launcher}/bin/suwayomi";
      icon = "${icon}";
      terminal = false;
      categories = ["Graphics" "Viewer"];
    };

    home.packages = [setPassword];
  };
}
