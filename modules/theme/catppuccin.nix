#=====================================================================#
# CATPPUCCIN THEME CONFIGURATION
#=====================================================================#
{lib, ...}: {
  #--------------------------------------------------------------------#
  #-- System Theme
  #--------------------------------------------------------------------#
  # Boot splash only: DMS's matugen themes the apps (theme/matugen.nix)
  catppuccin = lib.mkForce {
    enable = true;
    autoEnable = false;
    plymouth.enable = true;
    flavor = "mocha";
    accent = "mauve";
    # Stylix's console target owns console.colors; with both set there are 32
    # values, which the kernel rejects
    tty.enable = false;
  };
}
