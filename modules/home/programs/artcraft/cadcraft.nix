#=====================================================================#
# CADCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "cadcraft";
      version = "0.10.0";
      hash = "sha256-8mwsBdoiPDGJ0IxQrEMbnQc4YipLPYtENct+ypnKpgc=";
      description = "Computer-aided design and drafting";
    })
  ];
}
