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
    #--- System builder function
    mkSystem = hostname: let
      hostConfig = import "${self}/hosts/${hostname}/settings.nix";
      inherit (hostConfig) username;
    in {
      modules = [./hosts/${hostname}];
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

    #--- Formatter (nix fmt)
    # `nix fmt .`: alejandra 3.0.0 reads stdin when given no path
    formatter.x86_64-linux = inputs.alejandra.defaultPackage.x86_64-linux;
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
    # Own nixpkgs: 3.0.0 vendors a mimalloc that GCC 15 rejects
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # has no nixpkgs input
    # Own nixpkgs: following ours misses claude-code.cachix.org
    claude-code.url = "github:sadjow/claude-code-nix";

    #--- Applications
    # Own nixpkgs: following ours misses cache.forall.systems
    affinity-nix.url = "github:mrshmllow/affinity-nix";
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    tsunagu = {
      # The backend Moku 0.13.1 ships with; bump with `moku`
      url = "github:moku-project/Tsunagu/v0.4.1";
      flake = false;
    };
    moku = {
      # Built in home-manager media/moku; bump with `tsunagu`
      url = "github:moku-project/Moku/v0.13.1";
      flake = false;
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
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
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
