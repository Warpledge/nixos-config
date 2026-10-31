#=====================================================================#
# NIX HELPER (NH) AND BUILD MONITORING
#=====================================================================#
{
  lib,
  pkgs,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Nix Helper Configuration
  #--------------------------------------------------------------------#
  programs.nh = {
    enable = true;
    #--- maintenance.* in the machine's settings.nix
    clean = with machine.maintenance; {
      enable = clean != "off";
      dates = lib.mkIf (clean != "off") clean;
      extraArgs = "--keep-since ${toString keepDays}d --keep ${toString keepGenerations}";
    };
    flake = machine.flakePath; # flakePath in the machine's settings.nix
  };

  #--------------------------------------------------------------------#
  #-- Privilege Elevation
  #--------------------------------------------------------------------#
  #--- pkexec rather than sudo, so the password prompt is DMS's polkit dialog
  #--- (wm/dms-polkit) whether or not a terminal is attached
  environment.variables.NH_ELEVATION_STRATEGY = "pkexec";
  #--- nh calls pkexec up to three times per switch; keeping the authorization
  #--- for the calling process (as sudo's timestamp does) makes that one prompt
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" && subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
      }
    });
  '';

  #--------------------------------------------------------------------#
  #-- Build Monitoring Tools
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    nix-output-monitor # Monitor Nix builds with stats
    nvd # Show differences between NixOS generations
  ];
}
