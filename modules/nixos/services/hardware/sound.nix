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

    #--- The Katana's capture outranks every other device as graph driver, and
    #--- it only runs at 44.1k, so it pins any graph it joins to 44.1k and
    #--- stalls clients that force 48k (Rocksmith via PipeASIO). Below the
    #--- onboard output (1009) it follows instead and gets resampled.
    wireplumber.extraConfig."51-katana-driver" = {
      "monitor.alsa.rules" = [
        {
          matches = [{"node.name" = "alsa_input.hw_KATANA_0";}];
          actions.update-props."priority.driver" = 1000;
        }
      ];
    };
  };

  #--------------------------------------------------------------------#
  #-- System Packages for Audio
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [pulseaudioFull];
}
