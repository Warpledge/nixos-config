#=====================================================================#
# SUDO CONFIGURATION
#=====================================================================#
#--- Original Code by NotAShelf - https://github.com/notashelf/nyx
{lib, ...}: let
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
      wheelNeedsPassword = mkDefault true;
      execWheelOnly = mkForce true;
      extraConfig = ''
        Defaults lecture = never # Don't show sudo lecture on first use
        Defaults pwfeedback # Show password input feedback (asterisks)
        Defaults env_keep += "EDITOR DISPLAY" # PATH deliberately excluded: keeping it defeats secure_path
        Defaults timestamp_timeout = 300 # Cache password for 5 minutes
      '';
      extraRules = let
        # Only commands that cannot be turned into a root shell; sed, systemctl,
        # nixos-rebuild and the nix tools all can, so they need the password
        sudoRules = [
          "sync" # Sync filesystems
          "poweroff" # Power off system
          "reboot" # Reboot system
          "shutdown" # Shutdown system
          "dmesg" # Kernel messages
        ];
        # sudo matches the path a bare command resolves to, not its store path
        mkSudoRule = command: {
          command = "/run/current-system/sw/bin/${command}";
          options = ["NOPASSWD"];
        };
        sudoCommands = map mkSudoRule sudoRules;
      in [
        {
          groups = ["wheel"];
          commands = sudoCommands; # These commands without password
        }
      ];
    };
  };
}
