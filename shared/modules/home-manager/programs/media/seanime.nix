#=====================================================================#
# SEANIME CONFIGURATION
#=====================================================================#
#- Anime and manga media server, run as a user service with its web UI
#- opened as a Helium app window. Needs browsers.helium. Library, settings
#- and extensions live in Seanime's default data directory.
{
  pkgs,
  lib,
  ...
}: let
  port = 43211; # upstream default

  #--- nixpkgs still has 3.10.2; this bump drops out once it catches up.
  #--- 3.10.3's go.mod requires Go 1.27
  seanime =
    if lib.versionOlder pkgs.seanime.version "3.10.3"
    then
      (pkgs.seanime.override {buildGoModule = pkgs.buildGo127Module;}).overrideAttrs (finalAttrs: old: {
        version = "3.10.3";
        src = pkgs.fetchFromGitHub {
          owner = "5rahim";
          repo = "seanime";
          tag = "v${finalAttrs.version}";
          hash = "sha256-WPxLcEFlhMgJyCB+bMB2cil9vK2XpsFlT8hMbwhMbrc=";
        };
        env =
          old.env
          // {
            npmDeps = pkgs.fetchNpmDeps {
              src = "${finalAttrs.src}/seanime-web";
              hash = "sha256-vKAcaQU8ylUf8fXE2sqFzO6vFrHqZXb18uOkdzm2qjs=";
            };
          };
        vendorHash = "sha256-dCFDttoAqhXEErRtOS5Ti3CxyionxQQTglnOmsVRMto=";
      })
    else pkgs.seanime;
in {
  #--------------------------------------------------------------------#
  #-- Server
  #--------------------------------------------------------------------#
  systemd.user.services.seanime = {
    Unit.Description = "Seanime media server";
    Service = {
      #--- Torrent streaming and the torrent auto-downloader stay off regardless of in-app settings
      ExecStart = "${seanime}/bin/seanime --port ${toString port} --disable-features TorrentStreaming,ViewAutoDownloader,ManageAutoDownloader";
      Restart = "on-failure";
    };
    Install.WantedBy = ["default.target"];
  };

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.seanime = {
    name = "Seanime";
    comment = "Anime and manga media server";
    exec = "helium --app=http://127.0.0.1:${toString port}";
    icon = "${seanime.src}/seanime-web/public/seanime-logo.png";
    terminal = false;
    categories = ["AudioVideo" "Video"];
  };
}
