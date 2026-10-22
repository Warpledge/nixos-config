#=====================================================================#
# FIGCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "figcraft";
      version = "0.9.0";
      hash = "sha256-kJWZ4OdhLX+FFE9oXYDiDShaMpX/psXBBrYL49nepYo=";
      description = "Interface design and prototyping tool";
    })
  ];
}
