{
  self,
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    inputs.microvm.nixosModules.host
  ];

  microvm.vms = let hostConfig=config; in{
    proton-exit = {
      #specialArgs = {};

      config = {
        microvm.shares = [{
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          tag = "ro-store";
          proto = "virtiofs";
        }];
      };
      extraModules = [
        ({config, ...}: {
          imports = [self.inputs.agenix.nixosModules.default];
          services.tailscale = {
            enable = true;
            openFirewall = true;
            useRoutingFeatures = "server";
            authKeyFile = hostConfig.age.secrets.tailscaleKey.path;
            extraUpFlags = [
              "--hostname=${config.networking.hostName}"
            ]
            ++ config.services.tailscale.extraSetFlags;
            extraSetFlags = ["--advertise-exit-node"];
            disableUpstreamLogging = true;
            disableTaildrop = true;
          };
          networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
        })
      ];
    };
  };
  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
  };

  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;
    grub.enable = true;
  };

  networking = {
    hostName = "pecten";
  };
}
