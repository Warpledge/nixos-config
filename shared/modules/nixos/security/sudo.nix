#=====================================================================#
# SUDO CONFIGURATION
#=====================================================================#
#--- Original Code by NotAShelf - https://github.com/notashelf/nyx
{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkForce mkDefault;
in {
  #--------------------------------------------------------------------#
  #-- Sudo Configuration
  #--------------------------------------------------------------------#
  security = {
    sudo-rs.enable = mkForce false; # Disable sudo-rs (Rust rewrite, feature-incomplete)
    sudo = {
      enable = true; # Enable traditional sudo
      keepTerminfo = true; # Fix sudo in modern terminal emulators
      wheelNeedsPassword = mkDefault false; # Wheel group can sudo without password
      execWheelOnly = mkForce true; # Only wheel group can execute sudo
      extraConfig = ''
        Defaults lecture = never # Don't show sudo lecture on first use
        Defaults pwfeedback # Show password input feedback (asterisks)
        Defaults env_keep += "EDITOR PATH DISPLAY" # Keep these env vars as root
        Defaults timestamp_timeout = 300 # Cache password for 5 minutes
      '';
      extraRules = let
        sudoRules = with pkgs; [
          {
            package = coreutils;
            command = "sync";
          } # Sync filesystems
          {
            package = gnused;
            command = "sed";
          } # Sed text processing
          {
            package = hdparm;
            command = "hdparm";
          } # HDD/SSD optimization
          {
            package = nix;
            command = "nix-collect-garbage";
          } # Garbage collection
          {
            package = nix;
            command = "nix-store";
          } # Nix store operations
          {
            package = nixos-rebuild;
            command = "nixos-rebuild";
          } # System rebuild
          {
            package = nvme-cli;
            command = "nvme";
          } # NVMe management
          {
            package = systemd;
            command = "poweroff";
          } # Power off system
          {
            package = systemd;
            command = "reboot";
          } # Reboot system
          {
            package = systemd;
            command = "shutdown";
          } # Shutdown system
          {
            package = systemd;
            command = "systemctl";
          } # Systemd control
          {
            package = util-linux;
            command = "dmesg";
          } # Kernel messages
        ];
        mkSudoRule = rule: {
          command = "${rule.package}/bin/${rule.command}";
          options = ["NOPASSWD"];
        };
        sudoCommands = map mkSudoRule sudoRules;
      in [
        {
          groups = ["wheel"]; # Allow wheel group
          commands = sudoCommands; # These commands without password
        }
      ];
    };
  };
}
