{...}: {
  #=====================================================================#
  # FREETUBE
  #=====================================================================#

  imports = [
    ./settings.nix
    ./blocked-channels.nix
    ./youtube-dispatch.nix
  ];

  programs.freetube.enable = true;
}
