#=====================================================================#
# XSYSTEM4
#=====================================================================#
#- Native reimplementation of Wonderland Soft's System 4 engine (Lance 7
#- and others). Run `xsystem4 <game dir>`. Not in nixpkgs.
{pkgs, ...}: let
  xsystem4 = pkgs.stdenv.mkDerivation {
    pname = "xsystem4";
    version = "1.0.0-unstable-2026-10-27";

    src = pkgs.fetchFromGitHub {
      owner = "nunuhara";
      repo = "xsystem4";
      rev = "a85467d78eb5c7fb6e581d7fe5a6fdaec42b9ef7";
      fetchSubmodules = true; # libsys4
      hash = "sha256-1QvngNqbmPpZ4P8xmcyGWNo5snzf8LhxLafiOsmf4C4=";
    };

    #--- No cursor auto-move: the engine's "Auto-move Mouse Cursor" turned off
    postPatch = ''
      substituteInPlace src/input.c \
        --replace-fail "SDL_WarpMouseInWindow(sdl.window, wx, wy);" "(void)wx; (void)wy;"
    '';

    nativeBuildInputs = with pkgs; [meson ninja pkg-config flex bison];

    buildInputs = with pkgs; [
      SDL2
      freetype
      libffi
      libjpeg_turbo
      libwebp
      libpng
      libsndfile
      cglm
      zlib
      libGL
      glew
      ffmpeg # movie playback
    ];

    #--- Desktop GL + GLEW instead of GLES; no Scheme debugger
    mesonFlags = ["-Dopengles=disabled" "-Ddebugger=disabled"];

    meta = {
      description = "Implementation of Wonderland Soft's System 4 game engine";
      homepage = "https://github.com/nunuhara/xsystem4";
      license = pkgs.lib.licenses.gpl2Plus;
      mainProgram = "xsystem4";
    };
  };
in {
  #--------------------------------------------------------------------#
  #-- Package
  #--------------------------------------------------------------------#
  home.packages = [xsystem4];
}
