#=====================================================================#
# SYSTEM & HOME MANAGER CONFIGURATION
#=====================================================================#
{
  inputs,
  lib,
  machine,
  ...
}: let
  #--- Apply CachyOS kernel overlay if using cachyos kernel
  overlays = lib.optional (machine.kernel == "cachyos") inputs.cachyos-kernel.overlays.pinned;
in {
  #--------------------------------------------------------------------#
  #-- System ---> /modules/nixos
  #--------------------------------------------------------------------#
  #--- DO NOT CHANGE (set once per machine, in its settings.nix)
  system.stateVersion = machine.stateVersion;

  #--- Nixpkgs Configuration
  nixpkgs = {
    inherit overlays;
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  #--------------------------------------------------------------------#
  #-- Home Manager Module ---> /modules/home
  #--------------------------------------------------------------------#
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {inherit inputs machine;};
    #--- One home per user the machine lists
    users =
      lib.mapAttrs (name: user: {
        imports =
          [
            #--- Home System, handed `user` first: the routers read it in `imports`.
            #--- Not lib.modules.importApply: its extra nesting reorders the home
            #--- modules, which flips options that keep the last definition.
            (import ./home user)
            #--- Home Desktop (controlled by machine settings)
            ./wm/${machine.windowManager}/home
          ]
          #--- This person's own home modules, on every machine they log in on
          ++ lib.optional (builtins.pathExists ../users/${name}/home.nix) ../users/${name}/home.nix;
        #--- This user's settings, for every other home module (`user.media.mpv`)
        _module.args.user = user;
        home = {
          username = lib.mkDefault name;
          homeDirectory = "/home/${name}";

          #--- DO NOT CHANGE (set once per machine, in its settings.nix)
          inherit (machine) stateVersion;
        };
        programs.home-manager.enable = true;
      })
      machine.users;
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    #--- System Inputs
    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    inputs.catppuccin.nixosModules.catppuccin

    #--- System Modules
    ./nixos
    ./theme
    #--- Desktop Environment (controlled by machine settings)
    ./wm/${machine.windowManager}/session.nix
  ];
}
