#=====================================================================#
# HOME MANAGER MODULE IMPORTS
#=====================================================================#
{lib, ...}: {
  imports = [
    #--- Other
    ./programs
    ./mime.nix
    ./nixm.nix
    ./services.nix
    ./variables.nix
  ];

  #--- Clear stale HM backup files so activation never fails due to existing .bak
  home.activation.clearStaleBackups = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    find "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" -maxdepth 3 -name "*.bak" -delete 2>/dev/null || true
  '';
}
