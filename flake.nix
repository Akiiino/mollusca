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
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nur, nixos-hardware, agenix
    , flake-utils, ... }: {
      devShells = import "${self}/devshell.nix" { inherit self nixpkgs inputs; };
      nixosConfigurations = {
        gastropod = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            "${self}/machines/gastropod"
            "${self}/users/akiiino"
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.akiiino = { pkgs, nur, ... }: {
                imports = [
                  "${self}/modules/firefox.nix"
                  "${self}/modules/git.nix"
                  "${self}/modules/kitty.nix"
                  "${self}/modules/gnome.nix"
                  "${self}/users/akiiino/home.nix"
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
            "${self}/machines/scallop"
            "${self}/users/akiiino"
            "${self}/secrets/minor_secrets.nix"
            agenix.nixosModules.default
          ];

          specialArgs = { inherit self; };
        };
      };
    };
}
