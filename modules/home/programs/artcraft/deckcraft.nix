#=====================================================================#
# DECKCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "deckcraft";
      version = "0.9.0";
      hash = "sha256-RQb41H9E53m3RjqHLg/DX+qZ7t+c7/J2AcjBNEuSigU=";
      description = "Presentations and slide shows";
    })
  ];
}
