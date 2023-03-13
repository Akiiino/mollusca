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

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nur,
    nixos-hardware,
    agenix,
    flake-parts,
    ...
  }: let
    commonNixpkgsConfig = {
      nixpkgs = {
        config.allowUnfree = true;
        overlays = [inputs.nur.overlay] ++ (import "${self}/overlays");
      };
    };
    commonNixOSModules = [
      (
        {nix.registry.nixpkgs.flake = inputs.nixpkgs;}
        // commonNixpkgsConfig
      )
    ];
    mkHost = {
      hostname,
      arch ? "x86_64-linux",
      disabledModules ? [],
      customModules ? [],
    }:
      inputs.nixpkgs.lib.nixosSystem {
        system = arch;
        modules =
          [
            "${self}/machines/${hostname}"
            "${self}/users/akiiino"
            "${self}/secrets/minor_secrets.nix"
            agenix.nixosModules.default
            {disabledModules = disabledModules;}
          ]
          ++ commonNixOSModules
          ++ customModules;
        specialArgs = {
          inherit self;
        };
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      flake = {
        nixosConfigurations = {
          gastropod = mkHost {
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
          scallop = mkHost {
            hostname = "scallop";
          };
        };
      };
      systems = [
        "x86_64-linux"
      ];
      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devShells.default = import "${self}/devshell.nix" {inherit self pkgs inputs;};
      };
    };
}
