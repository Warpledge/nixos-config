#=====================================================================#
# FLAKE CONFIGURATION (WARPLEDGE'S NIXOS)
#=====================================================================#
{
  description = "Warpledge's NixOS Configuration";
  #--------------------------------------------------------------------#
  #-- Flake Outputs
  #--------------------------------------------------------------------#
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    #--- System variables
    system = "x86_64-linux";

    #--- System builder function
    mkSystem = hostname: let
      hostConfig = import "${self}/hosts/${hostname}/hostConfig/core.nix";
      inherit (hostConfig) username;
    in {
      inherit system;
      modules = [./hosts/${hostname}/${hostname}.nix];
      specialArgs = {
        inherit self inputs username hostname hostConfig;
      };
    };
  in {
    #--- NixOS Configurations
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem (mkSystem "desktop");
      laptop = nixpkgs.lib.nixosSystem (mkSystem "laptop");
    };
  };

  #--------------------------------------------------------------------#
  #-- Flake Inputs
  #--------------------------------------------------------------------#
  inputs = {
    #--- Core Dependencies
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #--- System Utilities & Tools
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    claude-code.url = "github:sadjow/claude-code-nix";

    #--- Applications
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    nixcord.url = "github:kaylorben/nixcord";
    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #--- Window Managers
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #--- DMS
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #--- Kernels
    cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    #--- Theme
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
