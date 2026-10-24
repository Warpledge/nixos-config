#=====================================================================#
# DEVELOPER TOOLS
#=====================================================================#
{
  pkgs,
  config,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    go
    gdb
    gnumake
    nodejs
    ilspycmd
    lazygit
    onefetch
    #--- Toolchains on first `rustup default stable`. lowPrio: Zed's nixpkgs
    #--- rust-analyzer wins over rustup's proxy of the same name
    (lib.lowPrio rustup)
  ];

  #--- Where `cargo install` puts binaries
  home.sessionPath = ["${config.home.homeDirectory}/.cargo/bin"];
}
