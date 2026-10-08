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
      cursors.enable = false; # keep Stylix's cursor (pointerCursor conflict)
      kvantum = {
        enable = true;
        apply = true; # Auto-apply theme via kvantum.kvconfig
      };
      zed.enable = false;
      opencode.enable = false; # stylix's opencode target owns tui.theme
      # Emits Lua-only colors that break configType = "hyprlang"; Stylix's
      # hyprland target owns them
      hyprland.enable = false;
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
    # Stylix's console target owns console.colors; with both set there are 32
    # values, which the kernel rejects
    tty.enable = false;
  };
}
