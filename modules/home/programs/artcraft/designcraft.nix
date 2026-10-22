#=====================================================================#
# DESIGNCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "designcraft";
      version = "0.11.0";
      hash = "sha256-fiRqb3k3GcmBjp0Ul+/sXiIwjJHkL/Ox/l82Z646a4w=";
      description = "Page layout and print design editor";
    })
  ];
}
