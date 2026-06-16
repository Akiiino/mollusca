{
  inputs = {
    WG-jail = {
      url = "github:Akiiino/WG-Jail";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Machine configuration
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    mini-agenix = {
      url = "github:Akiiino/mini-agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Packages outside nixpkgs
    gitsh = {
      url = "github:Akiiino/gitsh-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    secondbrain = {
      url = "github:Akiiino/secondbrain";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
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
      url = "github:Akiiino/kakoune";
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
    janet-lsp = {
      url = "github:Akiiino/janet-lsp-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    filewatcher123d = {
      url = "github:Akiiino/filewatcher123d-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    traveller = {
      url = "github:Akiiino/traveller";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    walker = {
      url = "github:abenz1267/walker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-manager.url = "github:viperML/wrapper-manager";
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
            glabrata = { };
          };

          packages."x86_64-linux".cups-brother-dcpl3520cdw = withSystem "x86_64-linux" (
            { pkgs, ... }: pkgs.callPackage ./packages/cups-brother-dcpl3520cdw.nix { }
          );
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
            devShells.default = import "${self}/devshell.nix" {
              inherit
                pkgs
                inputs
                inputs'
                system
                ;
            };
            packages = {

              zsh-jcd = pkgs.callPackage ./packages/zsh-jcd { };
            };
            checks = {
              statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
                cd ${self}
                statix check .
                touch $out
              '';
              deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
                cd ${self}
                deadnix --fail --exclude '**/hardware-configuration.nix' .
                touch $out
              '';
            };
          };
      }
    );
}
