#=====================================================================#
# FERDIUM CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Ferdium Package
  #--------------------------------------------------------------------#
  # Electron shell that stacks web messengers (Discord, Matrix, WhatsApp,
  # Slack, ...) into one window with per-service workspaces and a unified
  # unread count. Services and accounts are added in-app; state lives in
  # ~/.config/Ferdium and is not declarative.
  # The nixpkgs wrapper already adds the Wayland ozone flags when
  # NIXOS_OZONE_WL is set (home-manager/variables.nix).

  home.packages = with pkgs; [
    ferdium
  ];
}
