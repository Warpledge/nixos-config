#=====================================================================#
# NIRIUS ADDON
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Nirius Packages
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [
    nirius # scratchpad, focus-or-spawn, follow mode
  ];

  #--------------------------------------------------------------------#
  #-- Nirius Configuration
  #--------------------------------------------------------------------#
  programs.niri = {
    settings = {
      #--- Autostart
      spawn-at-startup = [
        {command = ["niriusd"];}
      ];

      #--- Keybinds
      binds = {
        # Show or hide every scratchpad window, floating over the current workspace
        "Mod+0" = {
          action.spawn = ["nirius" "scratchpad-show-all"];
          hotkey-overlay.title = "Show / hide scratchpad";
        };
        # Move the focused window into the scratchpad, or back out
        "Mod+Shift+0" = {
          action.spawn = ["nirius" "scratchpad-toggle"];
          hotkey-overlay.title = "Window to / from scratchpad";
        };
      };
    };
  };
}
