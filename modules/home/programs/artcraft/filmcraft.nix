#=====================================================================#
# FILMCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "filmcraft";
      version = "0.10.0";
      hash = "sha256-eHMYLFy6ZRMF/J90AT5TY39q0uqBj4d+LRpcBK3Z42E=";
      description = "Nonlinear video editor";
    })
  ];
}
