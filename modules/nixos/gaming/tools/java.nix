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
    enable = true;
    package = pkgs.jdk25; # Java 25 — GTNH 2.9's recommended runtime
    binfmt = lib.mkForce false; # Disable binfmt support (security concern)
  };

  # lowPrio so jdk25 owns `java`; jdk21 stays installed for Prism Launcher
  # and the 1.20.1 instances that ask for it by path.
  environment.systemPackages = [
    (lib.lowPrio pkgs.jdk21)
  ];
}
