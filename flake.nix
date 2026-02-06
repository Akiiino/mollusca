{
  inputs = {
    fiveETools = {
      url = "path:/home/akiiino/5etools/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.cl-nix-lite.inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "";
      };
      inputs.treefmt-nix.follows = "";
    };

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
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    arkenfox = {
      url = "github:dwarfmaster/arkenfox-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit.follows = "";
    };
    kakoune = {
      url = "github:mawww/kakoune";
      flake = false;
    };
    kak-yac = {
      url = "github:Akiiino/kak-yac";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    parinfer-rust = {
      url = "github:eraserhd/parinfer-rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crossmacro = {
      url = "github:alper-han/CrossMacro";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];

        flake = {
          lib = import "${self}/lib/default.nix" {
            inherit inputs self withSystem;
            inherit (self) lib;
            nixlib = nixpkgs.lib;
          };

          nixosConfigurations = self.lib.mkNixOSMachines {
            aspersum = { };
            nautilus = { };
            pecten = { };
            actinella = { };
            mussel = {
              system = "aarch64-linux";
            };
            entovalva = {
              system = "aarch64-linux";
            };
          };
        };

        perSystem =
          {
            pkgs,
            system,
            inputs',
            ...
          }:
          {
            _module.args.pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            formatter = pkgs.nixfmt-tree;
            devShells.default = import "${self}/devshell.nix" { inherit pkgs inputs'; };
            packages = {
              # musselSD = self.nixosConfigurations.mussel.config.formats.sd-aarch64;
              entovalvaSD = self.nixosConfigurations.entovalva.config.system.build.images.sd-card;
              nixos-manual = self.nixosConfigurations.aspersum.config.system.build.manual.manualHTML;
              cups-brother-dcpl3520cdw = pkgs.callPackage ./packages/cups-brother-dcpl3520cdw.nix { };
            };
          };
      }
    );
}
