#=====================================================================#
# MANGAYOMI CONFIGURATION
#=====================================================================#
#- Reader for manga, novels and anime. Sources are added in-app from
#- extension repos, including Mihon ones via its proxy server bundle.
#-
#- Deliberately the upstream AppImage rather than pkgs.mangayomi, which
#- tracks a release or two behind (0.8.0 against upstream 0.9.6 on
#- 2026-09-20). Switch back to the nixpkgs build once it catches up:
#- that drops the version bumps below back onto someone else.
{pkgs, ...}: let
  pname = "mangayomi";
  version = "0.9.6";

  src = pkgs.fetchurl {
    url = "https://github.com/kodjodevf/mangayomi/releases/download/v${version}/Mangayomi-v${version}-linux.AppImage";
    hash = "sha256-X/9JG9LhjvSENeA+mXgdWRSqeQpVf728zeAX0FrloTg=";
  };

  #-- Unpacked only to lift out the icon and desktop entry
  contents = pkgs.appimageTools.extract {inherit pname version src;};

  mangayomi = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    #--- Flutter GTK app; mpv backs the anime player
    extraPkgs = pkgs:
      with pkgs; [
        gtk3
        libepoxy
        libsecret
        mesa
        mpv
      ];

    #--- AppImage Exec points at /usr/bin; the wrapper is on PATH
    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
      install -Dm444 ${contents}/${pname}.png \
        $out/share/icons/hicolor/512x512/apps/${pname}.png
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=/usr/bin/${pname}' 'Exec=${pname}'
    '';

    meta = {
      description = "Read manga, light novels and watch anime";
      homepage = "https://github.com/kodjodevf/mangayomi";
      license = pkgs.lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [mangayomi];
}
