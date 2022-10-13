{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
        url = "github:nix-community/home-manager/master";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = github:nix-community/NUR/master;
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs@{nixpkgs, home-manager, nur, nixos-hardware, ...}: {
    nixosConfigurations.akiiinixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./config/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
        }
        nur.nixosModules.nur
        nixos-hardware.nixosModules.framework
      ];
    };
  };
}
