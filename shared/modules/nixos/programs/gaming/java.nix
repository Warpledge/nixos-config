#=====================================================================#
# JAVA CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Java Runtime Environment
  #--------------------------------------------------------------------#
  programs.java = {
    enable = true; # Enable Java support
    package = pkgs.jdk25; # Java 25 — required for GTNH 2.8.x
    binfmt = lib.mkForce false; # Disable binfmt support (security concern)
  };

  environment.systemPackages = [
    pkgs.jdk21 # Java 21 — for Prism Launcher / modded 1.20.1
  ];
}
