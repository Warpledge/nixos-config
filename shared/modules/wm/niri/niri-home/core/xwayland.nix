#=====================================================================#
# NIRI XWAYLAND SATELLITE CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: let
  #--- Pinned past 0.8.2 for the override-redirect focus fix (PR #494)
  # 0.8.2 focuses override-redirect windows, so Steam's menus lose focus and
  # self-dismiss. Drop this once nixpkgs ships a release containing add2795.
  src = pkgs.fetchFromGitHub {
    owner = "Supreeeme";
    repo = "xwayland-satellite";
    rev = "add2795134593faafce60e404a0a75df68e9ee0c";
    hash = "sha256-0TxfMgqW0/BLD4M942c5DCKYrtPvzsPJwvdcco4LQUM=";
  };

  xwayland-satellite-fixed = pkgs.xwayland-satellite.overrideAttrs (_: {
    inherit src;
    version = "0.8.2-unstable-2026-09-09";
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-s1gl9eR6Mt2QLrhfcowstPFjzwE/lz4PJhJzWYHoIHg=";
    };
  });
in {
  #--------------------------------------------------------------------#
  #-- Xwayland Satellite
  #--------------------------------------------------------------------#
  home.packages = [xwayland-satellite-fixed];

  programs.niri.settings = {
    xwayland-satellite = {
      enable = true;
      # Pin the binary explicitly; niri otherwise resolves it from PATH.
      path = lib.getExe xwayland-satellite-fixed;
    };
  };
}
