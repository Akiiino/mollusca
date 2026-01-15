{
  self,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${self}/modules/raspberrypi.nix"
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
    advertiseRoutes = "192.168.1.0/24";
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
      };
    };
    coredns = {
      enable = true;
      config = ''
        . {
          hosts ${self.inputs.stevenBlackHosts}/hosts {
            192.168.1.200 valetudo.akiiino.me
            192.168.1.15 akiiino.me
            fallthrough
          }
          # Cloudflare Forwarding
          forward . 1.1.1.1 1.0.0.1
          cache
        }
      '';
    };
    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."valetudo.akiiino.me" = {
        locations."/" = {
          proxyPass = "http://192.168.1.108";
        };
      };
    };
  };

  networking = {
    hostName = "mussel";
    domain = "";
    firewall = {
      allowedTCPPorts = [
        53 # DNS
        80 # nginx
      ];
      allowedUDPPorts = [
        53 # DNS
      ];
    };
  };
}
