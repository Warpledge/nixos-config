#=====================================================================#
# TONE3000 NAM PLAYER
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: let
  #--- Official TONE3000 NAM player: browses the site's capture/IR library from
  #--- inside the plugin. Not in nixpkgs; prebuilt release, so autoPatchelf it.
  #--- JUCE dlopens libcurl and the X11 extensions by soname at runtime rather
  #--- than linking them. dlopen resolves through the RUNPATH of the calling
  #--- object, so appendRunpaths covers the plugins too (they load into a DAW
  #--- and cannot be wrapped). Missing libcurl kills tone downloads.
  tone3000 = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "tone3000";
    version = "0.0.12";

    src = pkgs.fetchurl {
      url = "https://github.com/tone-3000/tone3000-plugin/releases/download/v${finalAttrs.version}/TONE3000-v${finalAttrs.version}-linux-x64.tar.gz";
      hash = "sha256-xF6l1k5u75kbFPGIOkJJ7RqIMlPbGp2fBgXgVAq6X8c=";
    };

    nativeBuildInputs = with pkgs; [autoPatchelfHook copyDesktopItems];

    buildInputs = with pkgs; [
      alsa-lib
      fontconfig
      stdenv.cc.cc.lib
      libx11
    ];

    #--- getLib, not "${p}/lib": curl defaults to its `bin` output, which has
    #--- no lib dir, and a dead runpath entry fails silently.
    appendRunpaths =
      (map (p: "${lib.getLib p}/lib") (with pkgs; [
        curl
        libGL
        libxcursor
        libxext
        libxinerama
        libxrandr
        libxscrnsaver
      ]))
      ++ ["/run/opengl-driver/lib"];

    #--- install.sh is for FHS distros; place the formats by hand instead so
    #--- LV2_PATH/CLAP_PATH/VST3_PATH below pick them up out of the profile.
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/lv2 $out/lib/clap $out/lib/vst3 $out/share/tone3000/presets
      install -Dm755 TONE3000 $out/bin/TONE3000
      install -Dm644 TONE3000.clap $out/lib/clap/TONE3000.clap
      cp -r TONE3000.lv2 $out/lib/lv2/
      cp -r TONE3000.vst3 $out/lib/vst3/
      cp factory-presets/*.t3kpreset $out/share/tone3000/presets/
      install -Dm644 tone3000.png $out/share/icons/hicolor/512x512/apps/tone3000.png

      runHook postInstall
    '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "tone3000";
        exec = "TONE3000";
        icon = "tone3000";
        desktopName = "TONE3000";
        comment = "Play NAM captures and IRs from the TONE3000 library";
        categories = ["AudioVideo" "Audio" "Music"];
        startupWMClass = "TONE3000";
      })
    ];
  });
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  #--- Official NAM player with built-in access to the TONE3000 tone
  #--- library. Standalone binary plus LV2/CLAP/VST3.
  home.packages = [tone3000];

  #--------------------------------------------------------------------#
  #-- TONE3000 Factory Presets
  #--------------------------------------------------------------------#
  # Shipped presets are read from the config dir. Only Factory is linked so
  # the user's own presets in the writable parent are left alone.

  xdg.configFile."TONE3000/Presets/Factory".source = "${tone3000}/share/tone3000/presets";
}
