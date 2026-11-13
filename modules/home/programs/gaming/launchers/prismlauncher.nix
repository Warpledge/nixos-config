#=====================================================================#
# PRISM LAUNCHER (MINECRAFT)
#=====================================================================#
{pkgs, ...}: {
  # Under niri, turn on "Use system installation of GLFW" in Prism's global settings
  # (Prism ships glfw-minecraft). Native Wayland centres the cursor when a GUI opens;
  # through XWayland it lands at random spots.
  home.packages = [pkgs.prismlauncher]; # multi-instance Minecraft launcher
}
