#=====================================================================#
# TWINTAIL LAUNCHER
#=====================================================================#
#- Gacha game launcher (Tauri). Not in nixpkgs; upstream ships a .deb, so
#- unpack and autoPatchelf it. The usr/ layout is kept because Tauri looks
#- for its resources at <exe dir>/../lib/twintaillauncher. Games run under
#- Proton runners it downloads itself, which go through nix-ld.
{pkgs, ...}: let
  twintail = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "twintaillauncher";
    version = "2.5.1";

    src = pkgs.fetchurl {
      url = "https://github.com/TwintailTeam/TwintailLauncher/releases/download/ttl-v${finalAttrs.version}/twintaillauncher_${finalAttrs.version}_amd64.deb";
      hash = "sha256-BHFspsk1zKcdDNUJ2YvZdkQ/cAUlSGkl/gJF0uiFrbg=";
    };

    nativeBuildInputs = with pkgs; [dpkg autoPatchelfHook wrapGAppsHook3];

    buildInputs = with pkgs; [
      webkitgtk_4_1
      gtk3
      libsoup_3
      glib-networking # TLS for the WebKit view
      dbus
      zlib
      stdenv.cc.cc.lib
    ];

    #--- Tray icon library is dlopened by soname, not linked
    runtimeDependencies = [pkgs.libayatana-appindicator];

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp -r usr $out/usr
      ln -s $out/usr/share $out/share
      ln -s $out/usr/bin/twintaillauncher $out/bin/twintaillauncher

      runHook postInstall
    '';

    meta = {
      description = "Launcher for anime gacha games";
      homepage = "https://github.com/TwintailTeam/TwintailLauncher";
      mainProgram = "twintaillauncher";
      platforms = ["x86_64-linux"];
    };
  });
in {
  home.packages = [twintail];
}
