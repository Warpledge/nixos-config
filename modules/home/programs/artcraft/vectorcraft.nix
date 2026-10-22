#=====================================================================#
# VECTORCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "vectorcraft";
      version = "0.14.0";
      hash = "sha256-iXV6HoBhZLlerizvm9+YvxoD7xCpssyKUL0FxUt0x5I=";
      description = "Vector art and SVG editor";
    })
  ];
}
