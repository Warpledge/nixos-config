#=====================================================================#
# FEEDBACK CONFIGURATION
#=====================================================================#
#- Guitar rhythm game with its own audio engine and VST hosting; reads
#- Guitar Pro tabs.
#-
#- Not in nixpkgs. Upstream publishes to a rolling `nightly` tag that
#- keeps the same filename, so a re-cut nightly fails the fetch on a
#- hash mismatch; that is the signal to bump the date and hash below.
{pkgs, ...}: let
  pname = "feedback";
  version = "0.3.0-unstable-2026-07-23";

  src = pkgs.fetchurl {
    url = "https://github.com/got-feedBack/feedBack-desktop/releases/download/nightly/feedback-0.3.0-x86_64.AppImage";
    hash = "sha256-5VvadJ26XQa+MjgFW8tnmA4Bzjc6ScMUpL8uEeGW7/Y=";
  };

  #-- Unpacked only to lift out the icons and desktop entry
  contents = pkgs.appimageTools.extract {inherit pname version src;};

  feedback = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    #--- Upstream Exec is `AppRun --no-sandbox %U`; only the command needs
    #--- rewriting, the flag stays (chrome-sandbox cannot be setuid in the store)
    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
      cp -r ${contents}/usr/share/icons $out/share/icons
      chmod -R u+w $out/share/icons
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    '';

    meta = {
      description = "Guitar rhythm game with an integrated audio engine, VST hosting and amp modeling";
      homepage = "https://github.com/got-feedBack/feedBack-desktop";
      license = pkgs.lib.licenses.agpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [feedback];
}
