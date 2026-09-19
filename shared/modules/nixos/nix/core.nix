#=====================================================================#
# NIX DAEMON CONFIGURATION AND OPTIMIZATION
#=====================================================================#
{
  pkgs,
  inputs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Language Server
  #--------------------------------------------------------------------#
  environment.systemPackages = [
    pkgs.nixd # Nix language server for IDE support
  ];

  #--------------------------------------------------------------------#
  #-- Nix Daemon Configuration
  #--------------------------------------------------------------------#
  nix = {
    nixPath = ["nixpkgs=${inputs.nixpkgs}"]; # Flake-based nixpkgs
    channel.enable = false; # flakes only
    daemonCPUSchedPolicy = "batch"; # Low CPU priority for daemon
    daemonIOSchedClass = "idle"; # Idle IO priority for daemon
    daemonIOSchedPriority = 7; # Lowest IO priority level
    optimise = {
      automatic = true;
      dates = ["04:00"];
    };

    #--------------------------------------------------------------------#
    #-- Nix Settings
    #--------------------------------------------------------------------#
    settings = {
      warn-dirty = false;
      min-free = "${toString (5 * 1024 * 1024 * 1024)}"; # Trigger GC at 5GB free
      max-free = "${toString (10 * 1024 * 1024 * 1024)}"; # Free up to 10GB
      trusted-users = ["root"]; # Who can manage store; no remote builders to trust
      max-jobs = "auto";
      cores = 0; # Use all CPU cores
      sandbox = true;
      sandbox-fallback = false; # Fail if sandbox not available
      system-features = ["nixos-test" "kvm" "recursive-nix" "big-parallel"];
      connect-timeout = 5; # Cache connection timeout (seconds)
      http-connections = 50; # Max parallel TCP connections
      log-lines = 30; # Show 30 lines for failed builds
      experimental-features = ["nix-command" "flakes"];
      keep-derivations = true; # Keep .drv files (for direnv)
      keep-outputs = true; # Keep build outputs (for direnv)
      builders-use-substitutes = true; # Use binary cache
    };
  };
}
