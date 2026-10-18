#=====================================================================#
# RETROSHELF CONFIGURATION
#=====================================================================#
#- Tidies an ES-DE / RetroDECK game library: pruning, metadata,
#- artwork, renames and imports.
#-
#- Not in nixpkgs, so this is the upstream AppImage. The asset's version
#- lags its release tag by one (tag v2026.10.12.17).
{pkgs, ...}: let
  pname = "retroshelf";
  version = "2026.1012.16";

  src = pkgs.fetchurl {
    url = "https://github.com/votex09/retroshelf/releases/download/v2026.10.12.17/RetroShelf-${version}-linux-x86_64.AppImage";
    hash = "sha256-wFhjj7WMnt3KW8iuCftBH03cg6LlLNodWKCN8y9Y3cY=";
  };

  #-- Unpacked only to lift out the icon and desktop entry
  contents = pkgs.appimageTools.extract {inherit pname version src;};

  retroshelf = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    #--- The self-updater would replace the AppImage, which lives in the store
    profile = ''
      export RETROSHELF_NO_UPDATES=1
    '';

    #--- Upstream Exec is `AppRun --no-sandbox %U`; the flag stays
    #--- (chrome-sandbox cannot be setuid in the store)
    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
      cp -r ${contents}/usr/share/icons $out/share/icons
      chmod -R u+w $out/share/icons
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    '';

    meta = {
      description = "Tidy up an ES-DE / RetroDECK game library";
      homepage = "https://github.com/votex09/retroshelf";
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [retroshelf];
}
