#=====================================================================#
# KEYD KEY REMAPPING DAEMON
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Keyd Configuration
  #--------------------------------------------------------------------#
  #--- Keyd is a key remapping daemon for Linux
  #--- See: https://github.com/rvaiya/keyd
  services = {
    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          capslock = "overload(control, esc)"; # Capslock: ESC on tap, CTRL when held
        };
      };
    };
  };
}
