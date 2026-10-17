#=====================================================================#
# USER ACCOUNT CONFIGURATION
#=====================================================================#
{
  lib,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- User Account Setup
  #--------------------------------------------------------------------#
  #--- One account per user in the machine's settings.nix. A new account
  #--- gets its password from `sudo passwd <name>`; none lives in the repo.
  users.users =
    lib.mapAttrs (name: user: {
      isNormalUser = true; # Non-root user account
      description = "${name} account";
      extraGroups =
        [
          "networkmanager" # Manage network connections
        ]
        ++ lib.optional user.admin "wheel" # Sudo privilege group (admin = true)
        ++ [
          "systemd-journal" # Read system journals
          "audio" # Audio device access
          "video" # Video device access
          "render" # GPU rendering access
          "input" # Input device access (keyboard, mouse)
          "power" # Power management
          "nix" # Nix daemon interaction
          "network" # Network configuration
          "git" # Git operations
          "libvirtd" # Virtual machine management
          "adbusers" # Android Debug Bridge access
          "kvm" # Kernel virtual machine access
          # GameMode's polkit rule only lets this group change governor/GPU clocks
          "gamemode"
        ]
        #--- Root-equivalent while docker runs: a member can bind-mount the host
        #--- filesystem into a container, so only admins get it, with the daemon
        ++ lib.optional (machine.docker.enable && user.admin) "docker";
    })
    machine.users;
}
