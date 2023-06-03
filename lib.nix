{
  inputs,
  self,
}: let
  lib = inputs.nixpkgs.lib;
in rec {
  commonNixpkgsConfig = {
    nixpkgs = {
      config.allowUnfree = true;
      overlays = [inputs.nur.overlay] ++ (import "${self}/overlays" {flake=self;});
    };
  };

  commonNixOSModules = [
    inputs.mollusca-secrets.nixosModules.secrets
    "${self}/users/akiiino"
    inputs.agenix.nixosModules.default
    {nix.registry.nixpkgs.flake = inputs.nixpkgs;}
    commonNixpkgsConfig
  ];

  commonDarwinModules = [
    {nix.registry.nixpkgs.flake = inputs.nixpkgs;}
    commonNixpkgsConfig
  ];

  mkNixOSMachine = {
    name,
    arch ? "x86_64-linux",
    disabledModules ? [],
    customModules ? [],
  }:
    inputs.nixpkgs.lib.nixosSystem {
      system = arch;
      modules =
        [
          "${self}/machines/${name}"
          {disabledModules = disabledModules;}
        ]
        ++ commonNixOSModules
        ++ customModules;
      specialArgs = {
        inherit self;
      };
    };

  mkDarwinMachine = {
    name,
    arch ? "x86_64-darwin",
    disabledModules ? [],
    customModules ? [],
  }:
    inputs.darwin.lib.darwinSystem {
      system = arch;
      modules =
        [
          "${self}/machines/${name}"
          {disabledModules = disabledModules;}
        ]
        ++ commonDarwinModules
        ++ customModules;
      specialArgs = {
        inherit self;
      };
    };

  takeLast = count: xs:
    lib.reverseList (lib.take count (lib.reverseList xs));

  mkVirtualHost = {
    fqdn,
    vhostConfig ? {},
  }: let
    domain = builtins.concatStringsSep "." (takeLast 2 (lib.splitString "." fqdn));
  in {
    "${fqdn}" =
      {
        forceSSL = true;
        enableACME = lib.mkForce false;
        useACMEHost = domain;
      }
      // vhostConfig;
  };

  mkProxy = {
    fqdn,
    port,
    extraConfig ? "",
    extraVhostConfig ? {},
  }:
    mkVirtualHost {
      inherit fqdn;
      vhostConfig =
        {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString port}";
            proxyWebsockets = true;
            extraConfig =
              ''
                proxy_pass_header Authorization;
                proxy_busy_buffers_size 512k;
                proxy_buffers 4 512k;
                proxy_buffer_size 256k;
              ''
              + extraConfig;
          };
        }
        // extraVhostConfig;
    };
}
