{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    nur.url = github:nix-community/NUR;

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./config/configuration.nix
        inputs.home-manager.nixosModules.home-manager
        nur.nixosModules.nur
        {
          home-manager.useGlobalPkgs = true;
        }
      ];
    };
  };
}
