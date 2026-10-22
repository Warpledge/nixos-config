#=====================================================================#
# PHOTOCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "photocraft";
      version = "0.12.0";
      hash = "sha256-2oITOa/Ok7cpkceQCij1iesGqIXgq1nqcC3eyaKArGY=";
      description = "Layered photo editor with PSD support";
    })
  ];
}
