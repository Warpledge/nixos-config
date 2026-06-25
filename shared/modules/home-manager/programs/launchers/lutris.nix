#=====================================================================#
# LUTRIS
#=====================================================================#
{pkgs, ...}: {
  # Wine-based launcher with per-game prefixes — also drives DLSite/DMM
  # visual-novel installers (see .notes/gaming/launcher-env-variables.md).
  #
  # nixpkgs lutris is FHS-wrapped; extraPkgs injects extra tools into that
  # sandbox so the in-app "Winetricks" menu (and the helpers it shells out
  # to) work — otherwise it can't find winetricks/cabextract on NixOS.
  home.packages = [
    (pkgs.lutris.override {
      extraPkgs = pkgs:
        with pkgs; [
          winetricks # in-Lutris Winetricks menu
          cabextract # font/cab extraction (corefonts etc.)
          p7zip # some Windows installers
        ];
    })
  ];
}
