{
  self,
  config,
  pkgs,
  ...
}: let
  private_subdomain = name: name + "." + config.minor_secrets.private_domain;
  public_subdomain = name: name + "." + config.minor_secrets.public_domain;
in {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./services/nitter.nix
    ./services/404.nix
  ];
  nix.settings.auto-optimise-store = true;

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "scallop";
  networking.domain = "";
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  security.sudo.wheelNeedsPassword = false;

  security.acme.acceptTerms = true;
  age.secrets.hetznerAPIKey.file = "${self}/secrets/hetzner.age";
  security.acme.defaults = {
    email = config.minor_secrets.acme_email;
    dnsProvider = "hetzner";
    credentialsFile = config.age.secrets.hetznerAPIKey.path;
    webroot = null;
  };
  security.acme.certs = {
    "${config.minor_secrets.private_domain}".extraDomainNames = [(private_subdomain "*")];
    "${config.minor_secrets.public_domain}".extraDomainNames = [(public_subdomain "*")];
  };

  environment.systemPackages = with pkgs; [kakoune hydroxide];

  networking.firewall.allowedTCPPorts = [80 443];
  services.grocy = {
    enable = true;
    hostName = private_subdomain "grocynew";
    settings = {
      currency = "EUR";
      culture = "en_GB";
      calendar.firstDayOfWeek = 1;
    };
  };

  age.secrets.nextcloudRootPass = {
    file = "${self}/secrets/nextcloud_root_pass.age";
    owner = "nextcloud";
    group = "nextcloud";
  };
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud25;
    enableBrokenCiphersForSSE = false;
    hostName = private_subdomain "nextcloud";
    https = true;
    notify_push.enable = false;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      # dbpassFile = "";  # TODO: add
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      adminuser = "root";
      adminpassFile = config.age.secrets.nextcloudRootPass.path;
      defaultPhoneRegion = "DE";
    };
    phpOptions = {
      "opcache.memory_consumption" = "256";
      "opcache.interned_strings_buffer" = "128";
    };
    extraApps = with pkgs.nextcloud25Packages.apps; {
      inherit polls forms unsplash calendar deck onlyoffice files_texteditor keeweb notes contacts groupfolders tasks bookmarks;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = ["nextcloud"];
    ensureUsers = [
      {
        name = "nextcloud";
        ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
      }
    ];
  };

  systemd.services."nextcloud-setup" = {
    requires = ["postgresql.service"];
    after = ["postgresql.service"];
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = let
      sharedSSL = vhost:
        vhost
        // {
          enableACME = pkgs.lib.mkForce false;
          useACMEHost = config.minor_secrets.private_domain;
          forceSSL = true;
        };
    in {
      "${config.services.grocy.hostName}" = sharedSSL {};
      "${config.services.nextcloud.hostName}" = sharedSSL {};
      "nc.${config.minor_secrets.private_domain}" = sharedSSL {globalRedirect = "${config.services.nextcloud.hostName}";};
    };
  };

  system.stateVersion = "22.05";
}
