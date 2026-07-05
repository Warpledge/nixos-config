#=====================================================================#
# SYSTEM & HOME MANAGER CONFIGURATION
#=====================================================================#
{
  inputs,
  username,
  hostname,
  lib,
  hostConfig,
  ...
}: let
  #--- Apply CachyOS kernel overlay if using cachyos kernel
  overlays =
    if hostConfig.kernel == "cachyos"
    then [inputs.cachyos-kernel.overlays.pinned]
    else [];
in {
  #--------------------------------------------------------------------#
  #-- NixOS Module ---> /modules/nixos
  #--------------------------------------------------------------------#
  imports = [
    #--- System Inputs
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    inputs.catppuccin.nixosModules.catppuccin

    #--- System Modules
    ./modules/nixos
    ./modules/theme
    #--- Desktop Environment (controlled by hostConfig)
    ./modules/wm/${hostConfig.windowManager}/${hostConfig.windowManager}-nixos
  ];

  #--- DO NOT CHANGE
  system.stateVersion = "25.11";

  #--- Nixpkgs Configuration
  nixpkgs = {
    inherit overlays;
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- Home Manager Module ---> /modules/home-manager
  #--------------------------------------------------------------------#
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit hostname inputs username hostConfig;};
    users.${username} = {
      imports = [
        #--- Home System
        ./modules/home-manager
        #--- Home Desktop (controlled by hostConfig.nix)
        ./modules/wm/${hostConfig.windowManager}/${hostConfig.windowManager}-home
      ];
      home = {
        username = lib.mkDefault "${username}";
        homeDirectory = "/home/${username}";

        #--- DO NOT CHANGE
        stateVersion = "25.11";
      };
      programs.home-manager.enable = true;
    };
  };
}
