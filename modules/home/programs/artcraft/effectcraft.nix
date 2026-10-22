#=====================================================================#
# EFFECTCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "effectcraft";
      version = "0.14.0";
      hash = "sha256-Bh4AwX09V8I92GwWiwPqqeVv85I8GeWsszkGmc8R7bw=";
      description = "Motion graphics and compositing tool";
    })
  ];
}
