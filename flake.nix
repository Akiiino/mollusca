{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR/master";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{ nixpkgs, home-manager, nur, nixos-hardware, ... }: {
    nixosConfigurations = rec {
      gastropod = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./config/configuration.nix
          ./config/users/akiiino
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.akiiino = { pkgs, nur, ... }: {
              imports = [
                ./config/modules/firefox.nix
                ./config/modules/git.nix
                ./config/modules/kitty.nix
                ./config/modules/gnome.nix
                ./config/users/akiiino/home.nix
              ];
            };
          }
          nur.nixosModules.nur
          nixos-hardware.nixosModules.framework
        ];
      };
      akiiinixos = gastropod;
      scallop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./config/machines/scallop/configuration.nix
          ./config/users/akiiino
        ];
      };
    };
  };
}
