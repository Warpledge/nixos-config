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
    inherit (nixpkgs) lib;
    settings = import ./lib/settings.nix {inherit lib;};

    #--- System builder function
    mkSystem = name: let
      inherit (settings.forMachine name) machine anyUser;
    in {
      modules = [./machines/${name}];
      specialArgs = {
        inherit self inputs machine anyUser;
      };
    };

    #--- Every folder in machines/ is a machine, except _template
    machines = lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "_" name) (builtins.readDir ./machines);

    #--- Someone else's computer: template defaults, one admin, every toggle off.
    #--- Must evaluate without anything from machines/ or users/warpledge/.
    stranger = let
      inherit
        (settings.forSettings {
          name = "stranger";
          own = {
            stateVersion = "26.05";
            users.alice = {};
          };
          readUser = _: {admin = true;};
        })
        machine
        anyUser
        ;
    in
      nixpkgs.lib.nixosSystem {
        modules = [
          ./modules
          {
            nixpkgs.hostPlatform = "x86_64-linux";
            fileSystems."/" = {
              device = "/dev/disk/by-label/nixos";
              fsType = "ext4";
            };
          }
        ];
        specialArgs = {inherit self inputs machine anyUser;};
      };
  in {
    #--- NixOS Configurations
    nixosConfigurations = lib.mapAttrs (name: _: nixpkgs.lib.nixosSystem (mkSystem name)) machines;

    #--- `nix flake check` evaluates the stranger machine (no build)
    #--- `.nixos` exposes the system, for listing what a stranger gets installed
    checks.x86_64-linux.stranger =
      nixpkgs.legacyPackages.x86_64-linux.writeText "stranger-eval" (
        builtins.unsafeDiscardStringContext stranger.config.system.build.toplevel.drvPath
      )
      // {nixos = stranger;};

    #--- Formatter (nix fmt)
    # `nix fmt .`: alejandra reads stdin when given no path
    formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.alejandra;
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
    nix-flatpak.url = "github:gmodena/nix-flatpak"; # has no nixpkgs input
    # Own nixpkgs: following ours misses claude-code.cachix.org
    claude-code.url = "github:sadjow/claude-code-nix";
    # Source only: ai/claude-desktop.nix builds its package.nix with our pkgs
    claude-desktop = {
      url = "github:kubastick/claude-desktop-nixos";
      flake = false;
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Its overlay builds mcp-nixos on its own fastmcp 4 / mcp 2 package set
    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      # The backend Moku 0.14.0 ships with; bump with `moku`
      url = "github:moku-project/Tsunagu/v0.6.0";
      flake = false;
    };
    moku = {
      # Built in home-manager media/moku; bump with `tsunagu`
      url = "github:moku-project/Moku/v0.14.1";
      flake = false;
    };
    retroshelf = {
      # Built in home-manager gaming/tools/retroshelf.nix; git, since the
      # github: tarball drops app/ (export-ignore)
      url = "git+https://github.com/votex09/retroshelf?ref=main&shallow=1";
      flake = false;
    };

    #--- Window Managers
    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #--- DMS (Dux Shell)
    dms = {
      url = "github:duxlabs-dev/dux-shell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:duxlabs-dev/dux-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-greeter = {
      url = "github:duxlabs-dev/dux-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-files = {
      url = "github:duxlabs-dev/dux-files";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #--- Kernels
    # Own nixpkgs: upstream says an override can mismatch patches and kernel
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
