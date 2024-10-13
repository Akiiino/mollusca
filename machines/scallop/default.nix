{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./disko.nix
    ./services/acme.nix
    ./services/keycloak.nix
    ./services/minio.nix
    ./services/nextcloud.nix
    ./services/nginx.nix
    ./services/oauth-proxy.nix
    ./services/outline.nix
    ./services/postgresql.nix
    ./services/secondbrain.nix
    ./services/tailscale.nix
    ./services/foundry.nix

    "${self}/users/akiiino"

    self.inputs.impermanence.nixosModules.impermanence
  ];

  options = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain being hosted by this server";
      default = config.mollusca.secrets.publicDomain;
      readOnly = true;
    };
    mkSubdomain = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = subdomain: subdomain + "." + config.domain;
      readOnly = true;
    };
  };
  config = {
    mollusca.isRemote = true;

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = "pride-bingo.seashell.social";
      port = 9132;
    };

    services.openssh = {
      enable = true;
      hostKeys = [
        {
          path = "/persist/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/persist/ssh/ssh_host_rsa_key";
          type = "rsa";
          bits = 4096;
        }
      ];
    };

    swapDevices = [
      {
        device = "/persist/swapfile";
        size = 4 * 1024;
      }
    ];

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
      ];
      files = [
        "/etc/machine-id"
      ];
    };

    systemd.network.networks."10-uplink" = {
      matchConfig = {
        Virtualization = true;
        Name = "en* eth*";
      };
      networkConfig.DHCP = "ipv4";
    };

    nix.settings.auto-optimise-store = true;

    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;
    networking.hostName = "scallop";
    networking.domain = "";

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
