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

  #--- RTKit only covers clients that ask it over D-Bus. Audio apps that call
  #--- sched_setscheduler directly need a non-zero RLIMIT_RTPRIO, which
  #--- defaults to 0. Applied at login, so it needs a fresh session.
  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "95";
    }
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
  ];

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
