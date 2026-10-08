#=====================================================================#
# RELINK MOD ORGANIZER CONFIGURATION
#=====================================================================#
#- GUI mod manager for Granblue Fantasy: Relink (RokyZevon). Front end
#- over GBFRDataTools: point it at the game, drop mods in its folder,
#- toggle them, hit "Mod it" and it patches data.i for you.
#- Not in nixpkgs; this wraps the prebuilt single-file Linux build.
#-
#- Self-contained .NET single-file app, so no external dotnet is needed,
#- but the bundled Avalonia/Skia stack dlopens fontconfig, freetype, GL
#- and X11 at runtime: nix-ld resolves the ELF interpreter and
#- LD_LIBRARY_PATH supplies those libs. Invariant globalization avoids ICU.
#-
#- The window also needs /run/opengl-driver/lib and LIBGL_ALWAYS_SOFTWARE=1
#- under Niri/XWayland on AMD; with hardware GLX the Avalonia window never
#- maps. Software rendering is fine for a config UI.
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
