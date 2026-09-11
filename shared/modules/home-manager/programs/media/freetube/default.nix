{...}: {
  #=====================================================================#
  # FREETUBE
  #=====================================================================#

  imports = [
    ./settings.nix
    ./blocked-channels.nix
    ./subscriptions.nix
  ];

  programs.freetube.enable = true;
}
