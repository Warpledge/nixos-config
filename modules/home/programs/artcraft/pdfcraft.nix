#=====================================================================#
# PDFCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "pdfcraft";
      version = "0.11.0";
      hash = "sha256-2FgQ4jbwlaqQCvIOAnZ5OyhDVybKvdTiHzStEEnTzDI=";
      description = "PDF reader and editor";
    })
  ];
}
