#=====================================================================#
# STEAM CONFIGURATION
#=====================================================================#
{
  config,
  pkgs,
  ...
}: let
  #--- Writes each user's steamGames setting into Steam's files (gaming/steam-games.nix)
  steam-games-apply =
    pkgs.writers.writePython3Bin "steam-games-apply" {
      libraries = [pkgs.python3Packages.vdf];
      flakeIgnore = ["E501"];
    } (builtins.replaceStrings ["@notifySend@"] ["${pkgs.libnotify}/bin/notify-send"]
      (builtins.readFile ./steam-games-apply.py));
in {
  environment.systemPackages = [steam-games-apply];

  #--------------------------------------------------------------------#
  #-- Steam Program Configuration
  #--------------------------------------------------------------------#
  programs = {
    steam = {
      enable = true;
      #--- Steam rewrites its config on exit, so changes made while it ran land here;
      #--- `steam -shutdown` only asks the running client to quit
      package = pkgs.steam.override {
        extraPreBwrapCmds = ''
          case " $* " in
            *" -shutdown "*) ;;
            *) ${steam-games-apply}/bin/steam-games-apply || true ;;
          esac
        '';
      };
      gamescopeSession = {
        enable = true;
        args = ["--hdr-enabled"]; # The HDR route: niri has no HDR output
      };
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      extest.enable = true; # Enable Wayland input support (critical)
      protontricks.enable = true; # Protontricks for Proton prefix management
      extraPackages = with pkgs; [
        config.programs.gamescope.package # Gamescope (patched, tools/gamescope)
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
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- Environment Variables
  #--------------------------------------------------------------------#
  environment.sessionVariables = {
    # Custom Proton tools
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
