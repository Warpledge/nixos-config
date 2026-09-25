#=====================================================================#
# NIX-VN - VISUAL NOVEL FSR UPSCALE WRAPPER
#=====================================================================#
#- `nix-vn %command%` upscales a fullscreen Proton game running below
#- native resolution with Wine's fullscreen-hack FSR (GE-Proton). Set the
#- game to fullscreen at its own resolution; windowed games are not scaled.
#- Vulkan paths only (DXVK/VKD3D), so WineD3D/DirectDraw titles get nothing.
#-   PROTON_ENABLE_WAYLAND=0        fullscreen hack exists only in the X11 driver;
#-                                  overrides the global =1 in variables.nix
#-   WINE_FULLSCREEN_FSR_STRENGTH   0 sharpest .. 5 softest; 5 keeps sharpening
#-                                  halos off line art and text
#- Launch-option values win, e.g. `WINE_FULLSCREEN_FSR_STRENGTH=3 nix-vn %command%`.
{pkgs, ...}: let
  nix-vn =
    pkgs.writeShellScriptBin "nix-vn"
    # bash
    ''
      if [[ $# -eq 0 ]]; then
        echo "usage: nix-vn <command> [args...]" >&2
        exit 1
      fi

      export PROTON_ENABLE_WAYLAND=0
      export WINE_FULLSCREEN_FSR="''${WINE_FULLSCREEN_FSR:-1}"
      export WINE_FULLSCREEN_FSR_STRENGTH="''${WINE_FULLSCREEN_FSR_STRENGTH:-5}"

      exec "$@"
    '';
in {
  home.packages = [nix-vn];
}
