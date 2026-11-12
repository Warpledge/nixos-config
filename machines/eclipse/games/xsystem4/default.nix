#=====================================================================#
# XSYSTEM4
#=====================================================================#
#- Native reimplementation of Wonderland Soft's System 4 engine (Lance 7
#- and others). Run `xsystem4 <game dir>`. Not in nixpkgs.
{pkgs, ...}: let
  xsystem4 = pkgs.stdenv.mkDerivation {
    pname = "xsystem4";
    version = "1.0.0-unstable-2026-11-06";

    src = pkgs.fetchFromGitHub {
      owner = "nunuhara";
      repo = "xsystem4";
      rev = "92cb183fa5705de142755f634931780612881cd1";
      fetchSubmodules = true; # libsys4
      hash = "sha256-I91rzLXf5Qq4QfolXga7aqheHRK9ln2CWDhs2GdxkkU=";
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
