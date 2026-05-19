#=====================================================================#
# USER ACCOUNT CONFIGURATION
#=====================================================================#
{username, ...}: {
  #--------------------------------------------------------------------#
  #-- User Account Setup
  #--------------------------------------------------------------------#
  users.users.${username} = {
    isNormalUser = true; # Non-root user account
    description = "${username} account";
    extraGroups = [
      "networkmanager" # Manage network connections
      "wheel" # Sudo privilege group
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
      "docker" # Docker container management
      "adbusers" # Android Debug Bridge access
      "kvm" # Kernel virtual machine access
    ];
  };

  #--------------------------------------------------------------------#
  #-- Nix Permissions
  #--------------------------------------------------------------------#
  #--- Allow user to interact with nix daemon
  nix.settings.allowed-users = ["${username}"];
}
