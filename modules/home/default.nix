#=====================================================================#
# HOME MANAGER MODULE IMPORTS
#=====================================================================#
#- `user` (this person's settings) comes first because programs/ reads it
#- in `imports`; modules/default.nix calls `import ./home user`
user: {lib, ...}: {
  _file = ./default.nix; # Error messages name this file, not the importer

  #--- Clear stale HM backup files so activation never fails due to existing .bak
  home.activation.clearStaleBackups = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    find "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" -maxdepth 3 -name "*.bak" -delete 2>/dev/null || true
  '';

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    #--- Other
    (import ./programs user)
    ./mime.nix
    ./nixm.nix
    ./services.nix
    ./variables.nix
  ];
}
