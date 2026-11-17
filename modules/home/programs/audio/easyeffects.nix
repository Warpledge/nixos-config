#=====================================================================#
# EASYEFFECTS OUTPUT LIMITER
#=====================================================================#
# dconf, which the daemon needs, is on in nixos/services/desktop.nix.
{
  #--------------------------------------------------------------------#
  #-- Daemon and Output Preset
  #--------------------------------------------------------------------#
  services.easyeffects = {
    enable = true;
    preset.output = "loudness";

    #--- Key names are EasyEffects' preset JSON (src/*_preset.cpp upstream);
    #--- left-out keys keep their defaults. The file is read-only, so save
    #--- GUI tweaks under a new preset name.
    extraPresets.loudness.output = {
      blocklist = [];
      plugins_order = ["limiter#0"];

      #--- Ceiling for loud peaks. No Autogain: it sits after each app's own
      #--- volume and turned a player set low back up.
      "limiter#0" = {
        bypass = false;
        threshold = -6.0;
      };
    };
  };
}
