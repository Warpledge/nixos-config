#=====================================================================#
# LUTRIS
#=====================================================================#
{pkgs, ...}: {
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
