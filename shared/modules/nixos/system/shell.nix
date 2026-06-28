#=====================================================================#
# SHELL CONFIGURATION (ZSH, FISH)
#=====================================================================#
{
  pkgs,
  username,
  ...
}: {
  #--- Default Shell
  programs.zsh.enable = true;
  users.users.${username}.shell = pkgs.zsh;

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
