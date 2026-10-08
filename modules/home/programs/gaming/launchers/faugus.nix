#=====================================================================#
# FAUGUS LAUNCHER
#=====================================================================#
{pkgs, ...}: {
  # Lightweight launcher for running Windows games via UMU-Launcher/Proton.
  home.packages = [pkgs.faugus-launcher];
}
