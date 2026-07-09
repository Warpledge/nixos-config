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
      autoEnable = true; # auto-enroll all ports (matches prior implicit behavior)
      flavor = "mocha";
      accent = "mauve";

      gtk.icon.enable = false;
      cursors.enable = false; # keep stylix Bibata-Modern-Ice cursor (avoids pointerCursor conflict)
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
    autoEnable = true; # auto-enroll all ports (matches prior implicit behavior)
    flavor = "mocha";
    accent = "mauve";
  };
}
