#=====================================================================#
# TONKATSU BOX CONFIGURATION
#=====================================================================#
#- Local collection manager for games, film, anime, manga, books and music;
#- wraps the prebuilt Flutter build, which isn't in nixpkgs.
#-
#- The bundle finds its own plugins ($ORIGIN/lib); LD_LIBRARY_PATH adds the
#- GTK3 libraries Flutter needs and /run/opengl-driver/lib for its GL backend.
{
  config,
  pkgs,
  lib,
  ...
}: let
  #-- Stable install location for the prebuilt bundle
  appDir = "${config.home.homeDirectory}/.local/opt/tonkatsu-box";

  #-- GTK3 stack the Flutter engine and bundled plugins link against
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
    pkgs.zlib
    pkgs.stdenv.cc.cc.lib
  ];

  #-- Wrapper: expose the GTK/GL libs, then exec
  tonkatsu-box =
    pkgs.writeShellScriptBin "tonkatsu-box"
    ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec "${appDir}/tonkatsu_box" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Wrapper Package
  #--------------------------------------------------------------------#
  home.packages = [tonkatsu-box];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.tonkatsu-box = {
    name = "Tonkatsu Box";
    comment = "Collection manager for games, film, anime, manga and books";
    exec = "tonkatsu-box";
    icon = "${appDir}/data/flutter_assets/assets/images/logo.png";
    terminal = false;
    categories = ["Utility" "Database"];
  };
}
