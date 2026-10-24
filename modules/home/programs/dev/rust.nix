#=====================================================================#
# RUST
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
  #--- Toolchains on first `rustup default stable`. lowPrio: Zed's nixpkgs
  #--- rust-analyzer wins over rustup's proxy of the same name
  home.packages = [(lib.lowPrio pkgs.rustup)];

  #--- Where `cargo install` puts binaries
  home.sessionPath = ["${config.home.homeDirectory}/.cargo/bin"];
}
