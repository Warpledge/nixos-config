#=====================================================================#
# RELINK MOD ORGANIZER CONFIGURATION
#=====================================================================#
#- Mod manager for Granblue Fantasy: Relink, over GBFRDataTools; wraps the
#- prebuilt Linux build, which isn't in nixpkgs.
#-
#- A self-contained .NET app whose Avalonia/Skia stack loads fontconfig,
#- freetype, GL and X11 at runtime, so nix-ld and LD_LIBRARY_PATH supply
#- them. On AMD under niri the window only appears with software rendering
#- (LIBGL_ALWAYS_SOFTWARE=1). Invariant globalization avoids ICU.
{
  pkgs,
  lib,
  ...
}: let
  #-- Stable install location for the prebuilt bundle
  appDir = "$HOME/.local/opt/relink-mod-organizer";

  #-- Runtime libraries the bundled Skia/Avalonia stack dlopens
  runtimeLibs = lib.makeLibraryPath [
    pkgs.fontconfig.lib
    pkgs.freetype
    pkgs.libglvnd
    pkgs.expat
    pkgs.zlib
    pkgs.libxkbcommon
    pkgs.stdenv.cc.cc.lib
    pkgs.libx11
    pkgs.libxext
    pkgs.libxrandr
    pkgs.libxi
    pkgs.libxcursor
    pkgs.libxrender
    pkgs.libxfixes
    pkgs.libxcb
    pkgs.libsm
    pkgs.libice
  ];

  #-- Wrapper: expose GUI libs + invariant globalization, then exec
  relink-mod-organizer =
    pkgs.writeShellScriptBin "relink-mod-organizer"
    ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib:${runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
      export LIBGL_ALWAYS_SOFTWARE=1
      # X11-only Avalonia app: launcher-spawned processes under Niri don't
      # inherit DISPLAY, so it dies with no X server. XWayland is on :0.
      export DISPLAY="''${DISPLAY:-:0}"
      exec "${appDir}/RelinkModOrganizer" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Wrapper Package
  #--------------------------------------------------------------------#
  home.packages = [relink-mod-organizer];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.relink-mod-organizer = {
    name = "Relink Mod Organizer";
    comment = "Mod manager for Granblue Fantasy: Relink";
    exec = "relink-mod-organizer";
    icon = "applications-games";
    terminal = false;
    categories = ["Game" "Utility"];
  };
}
