{ self, config, pkgs, ... }:
let subdomain = name: name + "." + config.minor_secrets.domain;
in {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
  ];

  nixpkgs.overlays = [ (import "${self}/overlays/hydroxide.nix") ];
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
  security.acme.defaults.email = config.minor_secrets.acme_email;

  environment.systemPackages = with pkgs; [ kakoune hydroxide ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.grocy = {
    enable = true;
    hostName = subdomain "grocynew";
    settings = {
      currency = "EUR";
      culture = "en_GB";
      calendar.firstDayOfWeek = 1;
    };
  };

  services.nitter = {
    enable = true;
    server.hostname = subdomain "nitter";
    server.address = "127.0.0.1";
    server.port = 13735;
    server.https = true;
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
    hostName = subdomain "nextcloud";
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
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [{
      name = "nextcloud";
      ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
    }];
  };

  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  age.secrets.hetznerAPIKey.file = "${self}/secrets/hetzner.age";
  security.acme.certs."${config.minor_secrets.domain}" = {
    domain = config.minor_secrets.domain;
    extraDomainNames = [ (subdomain "*") ];
    dnsProvider = "hetzner";
    credentialsFile = config.age.secrets.hetznerAPIKey.path;
    webroot = null;
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = let
      forceSSL = vhost:
        vhost // {
          enableACME = pkgs.lib.mkForce false;
          useACMEHost = config.minor_secrets.domain;
          forceSSL = true;
        };
    in {
      "${config.minor_secrets.domain}" = {
        locations."/".extraConfig = "return 404;";
        enableACME = true;
        forceSSL = true;
      };
      "${config.services.grocy.hostName}" = forceSSL { };
      "${config.services.nextcloud.hostName}" = forceSSL { };
      "${config.services.nitter.server.hostname}" = forceSSL {
        locations."/" = {
          proxyPass = "http://127.0.0.1:13735";
          proxyWebsockets = true;
          extraConfig =
            "proxy_ssl_server_name on;" +
            "proxy_pass_header Authorization;";
        };
      };
      "defaultDummy404ssl" = forceSSL {
        default = true;
        serverName = "_";
        locations."/".extraConfig = "return 404;";
      };
    };
  };

  age.secrets.keycloakDBPassword.file = "${self}/secrets/keycloak_db.age";
  services.keycloak = {
    enable = false;
    settings.hostname = "https://" + subdomain "test3";
    database.passwordFile = config.age.secrets.keycloakDBPassword.path;
    settings.https-port = 23571;
  };

  system.stateVersion = "22.05";
}
