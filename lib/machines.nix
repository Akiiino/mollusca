{
  inputs,
  self,
}: rec {
  commonNixpkgsConfig = {
    nixpkgs = {
      config.allowUnfree = true;
      overlays = import "${self}/overlays" {flake = self;};
    };
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  commonHomeManagerConfig = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  };

  commonModules = [
    commonNixpkgsConfig
    commonHomeManagerConfig
  ];

  commonNixOSModules = [
    inputs.nixos-generators.nixosModules.all-formats
    inputs.mollusca-secrets.nixosModules.secrets
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.default
    "${self}/modules/remote.nix"
    "${self}/modules/gui.nix"
    {
      users.mutableUsers = false;
      i18n.defaultLocale = "en_US.UTF-8";
      system.stateVersion = "23.11";
    }
  ];

  commonDarwinModules = [
    inputs.mollusca-secrets.darwinModules.secrets
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.default
  ];

  mkNixOSMachine = {
    name,
    arch ? "x86_64-linux",
    disabledModules ? [],
    extraModules ? [],
  }:
    inputs.nixpkgs.lib.nixosSystem {
      system = arch;
      modules =
        [
          "${self}/machines/${name}"
          {inherit disabledModules;}
        ]
        ++ commonModules
        ++ commonNixOSModules
        ++ extraModules;
      specialArgs = {
        inherit self;
      };
    };

  mkDarwinMachine = {
    name,
    arch ? "x86_64-darwin",
    disabledModules ? [],
    extraModules ? [],
  }:
    inputs.darwin.lib.darwinSystem {
      system = arch;
      modules =
        [
          "${self}/machines/${name}"
          {inherit disabledModules;}
        ]
        ++ commonModules
        ++ commonDarwinModules
        ++ extraModules;
      specialArgs = {
        inherit self;
      };
    };
}