#=====================================================================#
# LIGHTCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "lightcraft";
      version = "0.11.0";
      hash = "sha256-Oh6pnkqAalurf61+pnRNRnJ1+hP84iRxYYCKK0MOeKo=";
      description = "Non-destructive RAW photo editor";
    })
  ];
}
