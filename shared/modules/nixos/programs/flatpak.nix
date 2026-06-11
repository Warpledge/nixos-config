#=====================================================================#
# FLATPAK CONFIGURATION
#=====================================================================#
{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

  #--------------------------------------------------------------------#
  #-- Flatpak Package
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    flatpak # Flatpak runtime and package manager
  ];

  #--------------------------------------------------------------------#
  #-- Flatpak Service Configuration
  #--------------------------------------------------------------------#
  services.flatpak = {
    enable = true; # Enable Flatpak support
    packages = [
      # "com.github.tchx84.Flatseal" # Flatpak permissions manager GUI
    ];
    overrides = {
      global = {
        Context.sockets = [
          "wayland" # Enable Wayland socket
          "!x11" # Disable X11
          "!fallback-x11" # Disable X11 fallback
        ];
      };
    };
  };
}
