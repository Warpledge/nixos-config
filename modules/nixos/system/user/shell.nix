#=====================================================================#
# SHELL CONFIGURATION (ZSH, FISH)
#=====================================================================#
{
  lib,
  pkgs,
  machine,
  ...
}: {
  #--- Default Shell, for every user
  programs.zsh.enable = true;
  users.users = lib.mapAttrs (_: _: {shell = pkgs.zsh;}) machine.users;

  #--- Shell Packages
  environment.systemPackages = with pkgs; [
    carapace # Shell completion for multiple shells
    fish
    zsh
  ];

  #--- Available Shells
  environment.shells = with pkgs; [
    fish #
    zsh #
  ];
}
