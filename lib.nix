{
  inputs,
  self,
}: let
  lib = inputs.nixpkgs.lib;
in rec {
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
          inputs.agenix.nixosModules.default
          {disabledModules = disabledModules;}
        ]
        ++ commonNixOSModules
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
  }:
    mkVirtualHost {
      inherit fqdn;
      vhostConfig = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_pass_header Authorization;
          '';
        };
      };
    };
}
