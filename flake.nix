{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
    nur.url = "github:nix-community/NUR/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nur, nixos-hardware, agenix
    , flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShell = let pkgs = import nixpkgs { inherit system; };
      in pkgs.mkShell { packages = with pkgs; [ bash git agebox nixfmt agenix.packages."${system}".default ]; shellHook = ''export AGEBOX_PUBLIC_KEYS="secrets/keys"'';};
    }) // {
      nixosConfigurations = rec {
        gastropod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            ./machines/gastropod/configuration.nix
            ./users/akiiino
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.akiiino = { pkgs, nur, ... }: {
                imports = [
                  ./modules/firefox.nix
                  ./modules/git.nix
                  ./modules/kitty.nix
                  ./modules/gnome.nix
                  ./users/akiiino/home.nix
                ];
              };
            }
            nur.nixosModules.nur
            nixos-hardware.nixosModules.framework
          ];
        };
        scallop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            ./machines/scallop/configuration.nix
            ./users/akiiino
            ./secrets/minor_secrets.nix
            agenix.nixosModules.default
          ];

          specialArgs = { inherit self; };
        };
      };
    };
}
