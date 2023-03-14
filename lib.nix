{
  inputs,
  self,
}: rec {
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
          inputs.agenix.nixosModules.default
          {disabledModules = disabledModules;}
        ]
        ++ commonNixOSModules
        ++ customModules;
      specialArgs = {
        inherit self;
      };
    };
}
