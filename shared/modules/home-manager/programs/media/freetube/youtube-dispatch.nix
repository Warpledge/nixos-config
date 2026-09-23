#=====================================================================#
# YOUTUBE-DISPATCH - SEND YOUTUBE LINKS TO FREETUBE
#=====================================================================#
#- Registered as the http/https handler in mime.nix instead of Zen.
#- YouTube hosts are handed to FreeTube through its freetube:// deep
#- link, anything else falls through to Zen. music.youtube.com is
#- deliberately not matched: FreeTube has no YouTube Music support.
{pkgs, ...}: let
  youtube-dispatch =
    pkgs.writeShellScriptBin "youtube-dispatch"
    # bash
    ''
      url="''${1:-}"

      #--- bare host, with scheme, path and query stripped
      host="''${url#*://}"
      host="''${host%%/*}"
      host="''${host%%\?*}"

      case "$host" in
        youtube.com | www.youtube.com | m.youtube.com | youtu.be)
          #--- drop the browser's activation token so niri marks FreeTube
          #--- urgent instead of pulling focus to it
          unset XDG_ACTIVATION_TOKEN DESKTOP_STARTUP_ID
          exec ${pkgs.freetube}/bin/freetube "freetube://$url"
          ;;
      esac

      exec zen-beta "$@"
    '';
in {
  home.packages = [youtube-dispatch];

  #--- NoDisplay keeps it out of the app menu; it still resolves as a handler
  xdg.desktopEntries.youtube-dispatch = {
    name = "YouTube Dispatch";
    exec = "${youtube-dispatch}/bin/youtube-dispatch %u";
    noDisplay = true;
    mimeType = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };
}
