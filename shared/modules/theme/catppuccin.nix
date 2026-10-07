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
      enable = true;
      autoEnable = true; # auto-enroll all ports
      flavor = "mocha";
      accent = "mauve";

      gtk.icon.enable = false;
      cursors.enable = false; # keep stylix Bibata-Modern-Ice cursor (avoids pointerCursor conflict)
      kvantum = {
        enable = true;
        apply = true; # Auto-apply theme via kvantum.kvconfig
      };
      zed.enable = false;
      opencode.enable = false; # stylix's opencode target owns tui.theme
      hyprland.enable = false; # emits Lua-only colors that break configType = "hyprlang"; stylix's hyprland target owns them
    };
  };

  #--------------------------------------------------------------------#
  #-- System Theme
  #--------------------------------------------------------------------#
  catppuccin = lib.mkForce {
    enable = true;
    autoEnable = true; # auto-enroll all ports
    flavor = "mocha";
    accent = "mauve";
    tty.enable = false; # stylix's console target owns console.colors; both set means 32 values the kernel rejects
  };
}
