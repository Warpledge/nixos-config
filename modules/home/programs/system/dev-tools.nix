#=====================================================================#
# DEVELOPER TOOLS
#=====================================================================#
{
  pkgs,
  config,
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
    rustup # Toolchains on first `rustup default stable`
  ];

  #--- Where `cargo install` puts binaries
  home.sessionPath = ["${config.home.homeDirectory}/.cargo/bin"];
}
