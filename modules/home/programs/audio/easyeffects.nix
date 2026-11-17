#=====================================================================#
# EASYEFFECTS LOUDNESS LEVELLING
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
      plugins_order = ["autogain#0" "limiter#0"];

      #--- Pulls everything toward one loudness (LUFS), like Windows'
      #--- Loudness Equalization
      "autogain#0" = {
        bypass = false;
        target = -18.0;
        maximum-history = 15;
      };

      #--- Hard ceiling for spikes Autogain is too slow to catch
      "limiter#0" = {
        bypass = false;
        threshold = -1.0;
      };
    };
  };
}
