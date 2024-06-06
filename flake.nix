{
  inputs = {
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs2211.url = "github:NixOS/nixpkgs/nixos-22.11";
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

    # Nextcloud apps
    nc-announcementcenter = {
      url = "https://github.com/nextcloud-releases/announcementcenter/releases/download/v6.6.2/announcementcenter-v6.6.2.tar.gz";
      flake = false;
    };
    nc-oidc_login = {
      url = "github:pulsejet/nextcloud-oidc-login";
      flake = false;
    };
    nc-previewgenerator = {
      url = "github:akiiino/previewgenerator";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
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
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin"];

      flake = {
        lib = import "${self}/lib/default.nix" {inherit inputs self;};

        nixosConfigurations = {
          gastropod = self.lib.mkNixOSMachine {
            name = "gastropod";
          };

          nautilus = self.lib.mkNixOSMachine {
            name = "nautilus";
          };

          scallop = self.lib.mkNixOSMachine {
            name = "scallop";
          };

          mussel = self.lib.mkNixOSMachine {
            system = "aarch64-linux";
            name = "mussel";
          };
        };

        darwinConfigurations = {
          "workbook" = self.lib.mkDarwinMachine {
            name = "workbook";
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
    };
}
