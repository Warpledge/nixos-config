#=====================================================================#
# SOUND SYSTEM CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Disable PulseAudio
  #--------------------------------------------------------------------#
  services.pulseaudio.enable = false; # Disabled in favor of Pipewire

  #--------------------------------------------------------------------#
  #-- RTKit for Real-Time Priority
  #--------------------------------------------------------------------#
  security.rtkit.enable = true; # Enable RTKit for PipeWire real-time scheduling

  #--------------------------------------------------------------------#
  #-- ALSA Configuration
  #--------------------------------------------------------------------#
  hardware.alsa.enablePersistence = true; # Persist volume settings across reboots

  #--------------------------------------------------------------------#
  #-- Pipewire Configuration
  #--------------------------------------------------------------------#
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  #--------------------------------------------------------------------#
  #-- System Packages for Audio
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [pulseaudioFull];
}
