{
  inputs,
  self,
}: rec {
  commonNixpkgsConfig = {
    nixpkgs = {
      config.allowUnfree = true;
      overlays = import "${self}/overlays" {flake = self;};
    };
    nix = {
      settings.experimental-features = ["nix-command" "flakes"];

      registry = {
        nixpkgs.flake = inputs.nixpkgs;
        nixpkgs2211.flake = inputs.nixpkgs2211;
      };

    };
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
    ({pkgs, ...}: {
      users.mutableUsers = false;
      i18n.defaultLocale = "en_US.UTF-8";
      system = {
        extraSystemBuilderCmds = ''
          ln -sv ${pkgs.path} $out/nixpkgs
        '';
        stateVersion = "23.11";
      };
      nix.nixPath = ["nixpkgs=/run/current-system/nixpkgs"];
    })
  ];

  commonDarwinModules = [
    inputs.mollusca-secrets.darwinModules.secrets
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.default
    inputs.mac-app-util.darwinModules.default
    ({pkgs, ...}: {
      environment.postBuild = ''
        ln -sv ${pkgs.path} $out/nixpkgs
      '';
      nix.nixPath = ["nixpkgs=/run/current-system/sw/nixpkgs"];
    })
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
