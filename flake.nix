{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nur.url = "github:nix-community/NUR/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
    };

    ssh-to-age = {
      url = "github:Mic92/ssh-to-age";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    flake-parts.url = "github:hercules-ci/flake-parts";

    secondbrain = {
      url = "github:akiiino/secondbrain";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    mollusca-secrets = {
      url = "git+ssh://git@github.com/Akiiino/mollusca-secrets.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    nc-oidc_login = {
      url = "github:akiiino/nextcloud-oidc-login";
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
    nc-previewgenerator = {
      url = "github:akiiino/previewgenerator";
      flake = false;
    };
    nc-announcementcenter = {
      url = "https://github.com/nextcloud-releases/announcementcenter/releases/download/v6.5.1/announcementcenter-v6.5.1.tar.gz";
      flake = false;
    };

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitsh = {
      url = "github:akiiino/gitsh-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    autoraise = {
      url = "github:akiiino/autoraise-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nur,
    nixos-hardware,
    agenix,
    flake-parts,
    secondbrain,
    impermanence,
    darwin,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin"];

      flake = {
        lib = import "${self}/lib.nix" {inherit inputs self;};

        nixosConfigurations = {
          gastropod = self.lib.mkMachine {
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
                    "${self}/modules/firefox.nix"
                    "${self}/modules/git.nix"
                    "${self}/modules/kitty.nix"
                    "${self}/modules/gnome.nix"
                    "${self}/users/akiiino/home.nix"
                  ];
                };
              }
            ];
          };

          scallop = self.lib.mkMachine {
            hostname = "scallop";
            customModules = [
              secondbrain.nixosModules.CTO
              impermanence.nixosModules.impermanence
              ({config, ...}: {domain = config.secrets.publicDomain;})
            ];
          };
        };

        darwinConfigurations."workbook" = darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          modules = ["${self}/machines/workbook"];
          specialArgs = {
            inherit self;
          };
        };
      };

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devShells.default = import "${self}/devshell.nix" {inherit self pkgs inputs;};
      };
    };
}
