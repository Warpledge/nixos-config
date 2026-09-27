#=====================================================================#
# GALLERY READER CONFIGURATION
#=====================================================================#
#- Wraps a prebuilt Flutter Linux gallery client unpacked into
#- ~/.local/opt/gallery-reader. ~/.local/opt/gallery-reader/SOURCE records where #- it came from.
#-
#- The bundle's RUNPATH is $ORIGIN/lib, so its own plugins resolve on
#- their own. LD_LIBRARY_PATH supplies the GTK3 stack the Flutter engine
#- links against, WebKitGTK for the in-app login window, and
#- /run/opengl-driver/lib for the Impeller GL backend.
{
  config,
  pkgs,
  lib,
  ...
}: let
  #-- Stable install location for the prebuilt bundle
  appDir = "${config.home.homeDirectory}/.local/opt/gallery-reader";

  #-- GTK3 stack plus the webview plugin's WebKitGTK 4.1 and libsoup 3
  runtimeLibs = lib.makeLibraryPath [
    pkgs.gtk3
    pkgs.glib
    pkgs.pango
    pkgs.cairo
    pkgs.atk
    pkgs.gdk-pixbuf
    pkgs.harfbuzz
    pkgs.libepoxy
    pkgs.fontconfig.lib
    pkgs.webkitgtk_4_1
    pkgs.libsoup_3
    pkgs.zlib
    pkgs.stdenv.cc.cc.lib
  ];

  #-- Wrapper: the bundle's only top-level executable
  gallery-reader =
    pkgs.writeShellScriptBin "gallery-reader"
    ''
      exe=$(find "${appDir}" -maxdepth 1 -type f -executable -print -quit)
      [ -n "$exe" ] || { echo "gallery-reader: no bundle in ${appDir}" >&2; exit 1; }
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
      exec "$exe" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Wrapper Package
  #--------------------------------------------------------------------#
  home.packages = [gallery-reader];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.gallery-reader = {
    name = "Gallery Reader";
    exec = "gallery-reader";
    icon = "${appDir}/icon.png";
    terminal = false;
    categories = ["Graphics" "Viewer"];
  };
}
