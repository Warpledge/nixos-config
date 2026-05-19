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
    extraOptions = ''
      warn-dirty = false # Don't warn about dirty flakes
    '';
    channel.enable = false; # Disable nix-channel (we use flakes)
    daemonCPUSchedPolicy = "batch"; # Low CPU priority for daemon
    daemonIOSchedClass = "idle"; # Idle IO priority for daemon
    daemonIOSchedPriority = 7; # Lowest IO priority level
    optimise = {
      automatic = true; # Auto-optimize nix store
      dates = ["04:00"]; # Run at 4 AM daily
    };

    #--------------------------------------------------------------------#
    #-- Nix Settings
    #--------------------------------------------------------------------#
    settings = {
      auto-optimise-store = true; # Automatically optimize symlinks
      min-free = "${toString (5 * 1024 * 1024 * 1024)}"; # Trigger GC at 5GB free
      max-free = "${toString (10 * 1024 * 1024 * 1024)}"; # Free up to 10GB
      allowed-users = ["root" "@wheel" "nix-builder"]; # Who can use nix
      trusted-users = ["root" "@wheel" "nix-builder"]; # Who can manage store
      max-jobs = "auto"; # Parallel build jobs (auto-detect)
      cores = 0; # Use all CPU cores
      sandbox = true; # Build in sandboxed environments
      sandbox-fallback = false; # Fail if sandbox not available
      system-features = ["nixos-test" "kvm" "recursive-nix" "big-parallel"]; # Supported features
      connect-timeout = 5; # Cache connection timeout (seconds)
      http-connections = 50; # Max parallel TCP connections
      log-lines = 30; # Show 30 lines for failed builds
      experimental-features = ["nix-command" "flakes"]; # Enable flakes
      keep-derivations = true; # Keep .drv files (for direnv)
      keep-outputs = true; # Keep build outputs (for direnv)
      builders-use-substitutes = true; # Use binary cache
    };
  };
}
