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
    };
  };

  #--- Keybinds
  niri.keybinds = {
    # Show or hide every scratchpad window, floating over the current workspace
    scratchpad-show = {
      key = "Mod+0";
      title = "Show / hide scratchpad";
      action.spawn = ["nirius" "scratchpad-show-all"];
      group = "Windows";
    };
    # Move the focused window into the scratchpad, or back out
    scratchpad-toggle = {
      key = "Mod+Shift+0";
      title = "Window to / from scratchpad";
      action.spawn = ["nirius" "scratchpad-toggle"];
      group = "Windows";
    };
  };
}
