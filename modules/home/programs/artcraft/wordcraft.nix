#=====================================================================#
# WORDCRAFT
#=====================================================================#
{pkgs, ...}: {
  home.packages = [
    (import ./mk-app.nix pkgs {
      pname = "wordcraft";
      version = "0.9.0";
      hash = "sha256-UCKjLR/2LUZBAQwZ/cFrhlUWhoZTevnTBhWgPTTGr7A=";
      description = "Word processor";
    })
  ];
}
