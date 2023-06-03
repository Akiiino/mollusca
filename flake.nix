{
  inputs = {
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

    # Secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };
    mollusca-secrets = {
      url = "git+ssh://git@github.com/Akiiino/mollusca-secrets.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # Packages outside nixpkgs
    autoraise = {
      url = "github:akiiino/autoraise-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    gitsh = {
      url = "github:akiiino/gitsh-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    secondbrain = {
      url = "github:akiiino/secondbrain";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    nur.url = "github:nix-community/NUR/master";

    # Nextcloud apps
    nc-announcementcenter = {
      url = "https://github.com/nextcloud-releases/announcementcenter/releases/download/v6.5.1/announcementcenter-v6.5.1.tar.gz";
      flake = false;
    };
    nc-deck = {
      url = "https://github.com/nextcloud-releases/deck/releases/download/v1.9.0/deck-v1.9.0.tar.gz";
      flake = false;
    };
    nc-groupfolders = {
      url = "https://github.com/nextcloud-releases/groupfolders/releases/download/v14.0.1/groupfolders-v14.0.1.tar.gz";
      flake = false;
    };
    nc-oidc_login = {
      url = "github:akiiino/nextcloud-oidc-login";
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
    nur,
    secondbrain,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin"];

      flake = {
        lib = import "${self}/lib.nix" {inherit inputs self;};

        nixosConfigurations = {
          gastropod = self.lib.mkNixOSMachine {
            hostname = "gastropod";
            customModules = [
              nixos-hardware.nixosModules.framework
              nur.nixosModules.nur
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.akiiino = {
                  pkgs,
                  nur,
                  ...
                }: {
                  imports = [
                    "${self}/legacy_modules/firefox.nix"
                    "${self}/legacy_modules/git.nix"
                    "${self}/legacy_modules/kitty.nix"
                    "${self}/legacy_modules/gnome.nix"
                    "${self}/users/akiiino/home.nix"
                  ];
                };
              }
            ];
          };

          scallop = self.lib.mkNixOSMachine {
            hostname = "scallop";
            customModules = [
              secondbrain.nixosModules.CTO
              impermanence.nixosModules.impermanence
              ({config, ...}: {domain = config.secrets.publicDomain;})
            ];
          };
        };

        darwinConfigurations."workbook" = self.lib.mkDarwinMachine {
          hostname = "workbook";
        };
      };

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devShells.default = import "${self}/devshell.nix" {inherit self pkgs inputs;};
      };
    };
}
