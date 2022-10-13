{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    nur.url = github:nix-community/NUR/master;
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: {
    nixosConfigurations.akiiinixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./config/configuration.nix
        inputs.home-manager.nixosModules.home-manager
        inputs.nur.nixosModules.nur
        inputs.nixos-hardware.nixosModules.framework
        {
          home-manager.useGlobalPkgs = true;
        }
      ];
    };
  };
}
