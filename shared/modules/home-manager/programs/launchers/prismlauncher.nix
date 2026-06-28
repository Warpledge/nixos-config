#=====================================================================#
# PRISM LAUNCHER (MINECRAFT)
#=====================================================================#
{pkgs, ...}: {
  home.packages = [pkgs.prismlauncher]; # multi-instance Minecraft launcher
}
