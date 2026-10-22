#=====================================================================#
# ARTCRAFT APP BUILDER
#=====================================================================#
#- Wraps one ArtCraft app's upstream AppImage. Every app ships the same
#- layout: bin/<pname>, ai.storyteller.<pname>.desktop with a bare Exec,
#- hicolor icons and a MIME package. Not in nixpkgs, checked 2026-10-21.
#-
#- AppRun's self-integration into ~/.local/share only runs when $APPIMAGE
#- is set, which appimageTools leaves unset.
pkgs: {
  pname,
  version,
  hash,
  description,
}: let
  src = pkgs.fetchurl {
    url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-x86_64.AppImage";
    inherit hash;
  };

  #-- Unpacked only to lift out the desktop entry, icons and MIME types
  contents = pkgs.appimageTools.extract {inherit pname version src;};
in
  pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/usr/share/applications/*.desktop -t $out/share/applications
      install -Dm444 ${contents}/usr/share/mime/packages/*.xml -t $out/share/mime/packages
      cp -r ${contents}/usr/share/icons $out/share/icons
      chmod -R u+w $out/share/icons
    '';

    meta = {
      inherit description;
      homepage = "https://github.com/storytold/${pname}";
      license = pkgs.lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      mainProgram = pname;
    };
  }
