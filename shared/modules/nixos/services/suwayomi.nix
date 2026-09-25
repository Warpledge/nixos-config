#=====================================================================#
# SUWAYOMI MANGA SERVER
#=====================================================================#
#- Local manga reader server. The web UI is at http://localhost:4567.
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Suwayomi Server
  #--------------------------------------------------------------------#
  services.suwayomi-server = {
    enable = true;

    #--- Pinned ahead of nixpkgs (2.1.1867)
    package = pkgs.suwayomi-server.overrideAttrs (finalAttrs: _: {
      version = "2.3.2243";
      src = pkgs.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${finalAttrs.version}/Suwayomi-Server-v${finalAttrs.version}.jar";
        hash = "sha256-ghFBsy4XDUoC08vf7Vd+2PB70iOD/19BMuu1rkDpjdU=";
      };
    });

    settings.server = {
      port = 4567; # Module default 8080 is taken by Steam's webhelper
    };
  };

  #--- Its scratch dir is /tmp/Tachidesk, which a user-run instance can own
  #--- first and lock the service out of
  systemd.services.suwayomi-server.serviceConfig.PrivateTmp = true;
}
