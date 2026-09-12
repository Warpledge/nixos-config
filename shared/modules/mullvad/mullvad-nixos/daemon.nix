#=====================================================================#
# MULLVAD VPN CONFIGURATION
#=====================================================================#
#- Settings are applied with the mullvad CLI from a oneshot unit rather
#- than by templating /etc/mullvad-vpn/settings.json: the daemon owns
#- that file and rewrites it, so a symlink or template is clobbered.
#- Same shape as cosmic-manager's cosmic-ctl activation.
#-
#- Keys declared here are reasserted on every boot, so the GUI is
#- advisory for them. Relay and entry selection are deliberately NOT
#- managed, so switching exits by hand keeps working.
{
  config,
  lib,
  pkgs,
  ...
}: let
  #--------------------------------------------------------------------#
  #-- Declarative Settings
  #--------------------------------------------------------------------#
  settings = {
    #--- DNS content blockers. Lists are large and aggregated; verify a
    #--- category against the published list before enabling it.
    dns = {
      ads = true;
      trackers = true;
      malware = true;
      gambling = true;
      adultContent = false; # blocks JAST USA, Getchu, dmm.co.jp
      socialMedia = true; # also blocks t.co links and embedded tweets
    };

    lockdownMode = true; # kill switch: no traffic while the tunnel is down
    autoConnect = true; # daemon dials as soon as it starts
    lan = "allow"; # "block" to drop LAN traffic before the firewall sees it
    quantumResistant = "on";

    #--- directOnly makes a non-DAITA relay fail instead of silently
    #--- inserting a multihop entry behind your back.
    daita = {
      enable = true;
      directOnly = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- Apply Script
  #--------------------------------------------------------------------#
  onOff = b:
    if b
    then "on"
    else "off";

  dnsFlags = lib.concatStringsSep " " (
    lib.optional settings.dns.ads "--block-ads"
    ++ lib.optional settings.dns.trackers "--block-trackers"
    ++ lib.optional settings.dns.malware "--block-malware"
    ++ lib.optional settings.dns.gambling "--block-gambling"
    ++ lib.optional settings.dns.adultContent "--block-adult-content"
    ++ lib.optional settings.dns.socialMedia "--block-social-media"
  );

  applySettings = pkgs.writeShellApplication {
    name = "mullvad-apply-settings";
    runtimeInputs = [config.services.mullvad-vpn.package pkgs.coreutils];
    text = ''
      # The unit is up before the daemon accepts RPC.
      i=0
      until mullvad status >/dev/null 2>&1 || [ "$i" -ge 60 ]; do
        i=$((i + 1))
        sleep 1
      done

      mullvad dns set default ${dnsFlags}
      mullvad lockdown-mode set ${onOff settings.lockdownMode}
      mullvad auto-connect set ${onOff settings.autoConnect}
      mullvad lan set ${settings.lan}
      mullvad tunnel set quantum-resistant ${settings.quantumResistant}
      mullvad tunnel set daita ${onOff settings.daita.enable}
      mullvad tunnel set daita-direct-only ${onOff settings.daita.directOnly}

      # auto-connect covers boot; this covers a rebuild landing while the
      # tunnel happens to be down.
      if mullvad status | grep -q '^Disconnected'; then
        mullvad connect
      fi
    '';
  };
in {
  #--------------------------------------------------------------------#
  #-- Mullvad VPN Service
  #--------------------------------------------------------------------#
  services.mullvad-vpn = {
    enable = true;
    gui.enable = true;
    enableEarlyBootBlocking = true; # block traffic before the network is up
  };

  #--------------------------------------------------------------------#
  #-- Settings Enforcement
  #--------------------------------------------------------------------#
  systemd.services.mullvad-settings = {
    description = "Apply declarative Mullvad settings";
    after = ["mullvad-daemon.service"];
    requires = ["mullvad-daemon.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe applySettings;
    };
  };

  #--------------------------------------------------------------------#
  #-- Mullvad GUI Dependencies
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    libglvnd # OpenGL library (required for Mullvad VPN GUI)
  ];
}
