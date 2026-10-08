#=====================================================================#
# GHOSTTY TERMINAL CONFIGURATION
#=====================================================================#
{config, ...}: {
  #--------------------------------------------------------------------#
  #-- Settings
  #--------------------------------------------------------------------#
  programs.ghostty = {
    enable = true;

    settings = {
      #--- Window Settings
      window-padding-x = 10;
      window-padding-y = 10;
      window-width = 1200;
      window-height = 600;
      window-save-state = "never";

      #--- Cursor Settings
      cursor-style = "bar";
      cursor-style-blink = false;

      #--- Scrollback
      scrollback-limit = 10000;

      #--- Font Settings (from Stylix)
      font-family = config.stylix.fonts.monospace.name;
      font-size = 12;

      #--- Shell Integration
      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title";

      #--- Mouse
      mouse-hide-while-typing = true;
      copy-on-select = false;

      #--- Miscellaneous
      confirm-close-surface = false;
      quit-after-last-window-closed = false;

      #--- Theme (will inherit from Stylix/Catppuccin)
      # Theme settings are handled by system-wide theming
    };
  };
}
