#=====================================================================#
# STEAM CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Steam Program Configuration
  #--------------------------------------------------------------------#
  programs = {
    steam = {
      enable = true; # Enable Steam
      gamescopeSession.enable = true; # Enable Gamescope session (Wayland compositor)
      remotePlay.openFirewall = true; # Allow Steam Remote Play through firewall
      dedicatedServer.openFirewall = false; # Don't open firewall for dedicated servers
      extest.enable = true; # Enable Wayland input support (critical)
      protontricks.enable = true; # Protontricks for Proton prefix management
      extraCompatPackages = [
        pkgs.proton-ge-bin # GE-Proton (improved game compatibility)
      ];
      extraPackages = with pkgs; [
        gamescope # Gamescope compositor
        pipewire # Audio server
        libXcursor # X11 cursor library
        libXi # X11 input library
        libXinerama # X11 multihead library
        libXScrnSaver # X11 screensaver library
        libpng # PNG image library
        libpulseaudio # PulseAudio compatibility
        libvorbis # Vorbis audio codec
        stdenv.cc.cc.lib # C runtime libraries
        libkrb5 # Kerberos authentication
        keyutils # Kernel key utilities
        libc #r2modman (Tisk of Rain 2)
      ];
      localNetworkGameTransfers.openFirewall = true; # Allow local file transfers
    };
  };

  #--------------------------------------------------------------------#
  #-- Environment Variables
  #--------------------------------------------------------------------#
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d"; # Custom Proton tools
  };
}
