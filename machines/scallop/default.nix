{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./services/acme.nix
    ./services/keycloak.nix
    ./services/nitter.nix
    ./services/libreddit.nix
    ./services/grocy.nix
    ./services/nextcloud.nix
    ./services/postgresql.nix
    #./services/gitea.nix
    ./services/secondbrain.nix
    #./services/komga.nix
    ./services/oauth-proxy.nix
    ./services/404.nix
    ./disko.nix
  ];

  options = {
    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain being hosted by this server";
    };
    mkSubdomain = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = subdomain: subdomain + "." + config.domain;
      readOnly = true;
    };
  };
  config = {
    users.mutableUsers = false;
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
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

    boot.cleanTmpDir = true;
    zramSwap.enable = true;
    networking.hostName = "scallop";
    networking.domain = "";
    security.sudo.wheelNeedsPassword = false;

    environment.systemPackages = with pkgs; [kakoune hydroxide];

    networking.firewall.allowedTCPPorts = [80 443];
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    system.stateVersion = "22.05";
  };
}
