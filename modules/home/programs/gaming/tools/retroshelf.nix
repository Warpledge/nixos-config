#=====================================================================#
# RETROSHELF CONFIGURATION
#=====================================================================#
#- Tidies an ES-DE / RetroDECK game library: pruning, metadata,
#- artwork, renames and imports.
#-
#- Built from the `retroshelf` input (main), so a flake update brings the
#- new version with no hash to bump. Run unpackaged, the app finds its
#- Python helper through RETROSHELF_PYTHON and its updater stays off.
{
  pkgs,
  inputs,
  ...
}: let
  src = inputs.retroshelf;

  #--- Matches the major in app/package.json
  electron = pkgs.electron_44;

  #--- cryptography decrypts PS3 / PSP packages (as in upstream's build)
  python = pkgs.python3.withPackages (ps: [ps.cryptography]);

  retroshelf = pkgs.stdenvNoCC.mkDerivation {
    pname = "retroshelf";
    version = "0-unstable-${builtins.substring 0 8 src.lastModifiedDate}";
    inherit src;

    nativeBuildInputs = [pkgs.makeWrapper pkgs.copyDesktopItems];

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "retroshelf";
        desktopName = "RetroShelf";
        comment = "Tidy up an ES-DE / RetroDECK game library";
        exec = "retroshelf %U";
        icon = "retroshelf";
        categories = ["Game"];
      })
    ];

    #--- The helper imports lib/ from the repo root, so the tree stays whole
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/retroshelf
      cp -r app lib vendor assets $out/share/retroshelf/
      install -Dm444 assets/icon-256.png \
        $out/share/icons/hicolor/256x256/apps/retroshelf.png
      makeWrapper ${electron}/bin/electron $out/bin/retroshelf \
        --add-flags $out/share/retroshelf/app \
        --set RETROSHELF_PYTHON ${python}/bin/python3
      runHook postInstall
    '';

    meta = {
      description = "Tidy up an ES-DE / RetroDECK game library";
      homepage = "https://github.com/votex09/retroshelf";
      platforms = ["x86_64-linux"];
      mainProgram = "retroshelf";
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [retroshelf];
}
