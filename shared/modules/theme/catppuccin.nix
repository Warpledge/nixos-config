#=====================================================================#
# CATPPUCCIN THEME CONFIGURATION
#=====================================================================#
{
  lib,
  inputs,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Home Manager Theme
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    imports = [inputs.catppuccin.homeModules.catppuccin];
    catppuccin = lib.mkForce {
      #--- Global Settings
      enable = true; # apply automatically globally
      flavor = "mocha";
      accent = "mauve";

      gtk.icon.enable = false;
      kvantum = {
        enable = true;
        apply = true; # Auto-apply theme via kvantum.kvconfig
      };
      zed.enable = false;
    };
  };

  #--------------------------------------------------------------------#
  #-- System Theme
  #--------------------------------------------------------------------#
  catppuccin = lib.mkForce {
    enable = true; # apply automatically globally
    flavor = "mocha";
    accent = "mauve";
  };
}
