#=====================================================================#
# NIRI SWITCHER ADDON
#=====================================================================#
{
  config,
  pkgs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Niri Switcher Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    niriswitcher # alt-tab functionality
  ];

  #--------------------------------------------------------------------#
  #-- Niri Switcher Configuration
  #--------------------------------------------------------------------#
  programs.niri = {
    settings = {
      #--- Autostart
      spawn-at-startup = [
        {command = ["niriswitcher"];}
      ];

      #--- Keybinds
      binds = {
        #--- Window Switching
        "Alt+Tab".action.spawn = ["niriswitcherctl" "show" "--window"];
        "Alt+Shift+Tab".action.spawn = ["niriswitcherctl" "show" "--window"];

        #--- Workspace Switching
        "Alt+Grave".action.spawn = ["niriswitcherctl" "show" "--workspace"];
        "Alt+Shift+Grave".action.spawn = ["niriswitcherctl" "show" "--workspace"];
      };
    };
  };
}
