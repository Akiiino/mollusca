{
  inputs = {
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-2505.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Machine configuration
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    nh.url = "github:viperML/nh";

    # Secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.home-manager.follows = "home-manager";
    };
    mollusca-secrets = {
      url = "git+ssh://git@github.com/Akiiino/mollusca-secrets.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packages outside nixpkgs
    nixcasks = {
      url = "github:jacekszymanski/nixcasks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    autoraise = {
      url = "github:akiiino/autoraise-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    gitsh = {
      url = "github:akiiino/gitsh-flake";
      # inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-parts.follows = "flake-parts";
    };
    secondbrain = {
      url = "github:akiiino/secondbrain";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    stevenBlackHosts = {
      url = "github:StevenBlack/hosts";
      flake = false;
    };
    firefox-addons = {
      url = gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arkenfox = {
      url = "github:dwarfmaster/arkenfox-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    foundryvtt.url = "github:reckenrode/nix-foundryvtt";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-2505,
    agenix,
    darwin,
    flake-parts,
    haumea,
    home-manager,
    impermanence,
    nixos-hardware,
    secondbrain,
    stevenBlackHosts,
    nixos-generators,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];

      flake = {
        lib = import "${self}/lib/default.nix" {inherit inputs self withSystem;};

        nixosConfigurations = self.lib.mkNixOSMachines {
          gastropod = {};
          aspersum = {};
          nautilus = {};
          scallop = {pkgs = nixpkgs-2505;};
          mussel = {system = "aarch64-linux";};
        };

        darwinConfigurations = self.lib.mkDarwinMachines {
          workbook = {
            system = "aarch64-darwin";
          };
        };
      };

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devShells.default = import "${self}/devshell.nix" {inherit self pkgs inputs;};
        packages = {
          musselSD = self.nixosConfigurations.mussel.config.formats.sd-aarch64;
        };
      };
    });
}
