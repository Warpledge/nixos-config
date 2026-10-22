#=====================================================================#
# SOUNDCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "soundcraft";
      version = "0.11.0";
      hash = "sha256-to+NF5BKYIQff+bdFkN2lwtBzDiNa4BBrRgiYlH1v7s=";
      description = "Audio recording and editing workstation";
    })
  ];
}
