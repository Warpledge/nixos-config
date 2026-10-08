#=====================================================================#
# STREAMLINK TWITCH GUI CONFIGURATION
#=====================================================================#
#- Browses Twitch and hands the stream to streamlink, which pipes it
#- into mpv. Nothing touches Twitch's web player, so no ads, and the
#- follow list is local rather than tied to a Twitch account.
#-
#- Not in nixpkgs, so this is the upstream AppImage (v2.5.3, tagged
#- 2024-11-04). Switch to pkgs.streamlink-twitch-gui if it ever lands.
{
  config,
  pkgs,
  ...
}: let
  pname = "streamlink-twitch-gui";
  version = "2.5.3";

  src = pkgs.fetchurl {
    url = "https://github.com/streamlink/streamlink-twitch-gui/releases/download/v${version}/${pname}-v${version}-x86_64.AppImage";
    hash = "sha256-6KtwQSRsjtwo6AAmTmEZsuSUuXdOlsAI6fD4zBnvnns=";
  };

  #-- Unpacked only to lift out the icons and desktop entry
  contents = pkgs.appimageTools.extract {inherit pname version src;};

  streamlink-twitch-gui = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    #--- Both players are spawned from inside the FHS env, not from PATH;
    #--- the home-manager mpv carries the scripts (uosc) plain mpv lacks
    extraPkgs = pkgs: [
      (
        if config.programs.mpv.enable
        then config.programs.mpv.finalPackage
        else pkgs.mpv
      )
      pkgs.streamlink
    ];

    #--- Desktop entry already carries bare Exec and Icon names
    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
      cp -r ${contents}/usr/share/icons $out/share/icons
      chmod -R u+w $out/share/icons
    '';

    meta = {
      description = "Browse Twitch.tv and watch streams in your videoplayer of choice";
      homepage = "https://github.com/streamlink/streamlink-twitch-gui";
      license = pkgs.lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [streamlink-twitch-gui];

  #--------------------------------------------------------------------#
  #-- Streamlink Config
  #--------------------------------------------------------------------#
  #- Read by the GUI's streamlink when its player preset is "default"
  programs.streamlink = {
    enable = true;
    package = null; # The GUI bundles its own streamlink
    settings.player = "mpv";
  };
}
