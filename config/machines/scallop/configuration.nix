{ self, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect

  ];

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

  environment.systemPackages = with pkgs; [ kakoune ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.grocy = {
    enable = true;
    hostName = "test.seashell.social";
  };

  services.nitter = {
    enable = true;
    server.hostname = "test2.seashell.social";
    server.address = "127.0.0.1";
    server.port = 13735;
    server.https = true;
  };

  age.secrets.hetznerAPIKey.file = "${self}/secrets/hetzner.age";
  security.acme.certs."seashell.social" = {
    domain = "seashell.social";
    extraDomainNames = [ "*.seashell.social" ];
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
      seashellSSL = vhost:
        vhost // {
          enableACME = pkgs.lib.mkForce false;
          useACMEHost = "seashell.social";
          forceSSL = true;
        };
    in {
      "seashell.social" = {
        locations."/".extraConfig = "return 404;";
        enableACME = true;
        forceSSL = true;
      };
      "test.seashell.social" = seashellSSL { };
      "test2.seashell.social" = seashellSSL {
        locations."/" = {
          proxyPass = "http://127.0.0.1:13735";
          proxyWebsockets = true; # needed if you need to use WebSocket
          extraConfig =
            # required when the target is also TLS server with multiple hosts
            "proxy_ssl_server_name on;" +
            # required when the server wants to use HTTP Authentication
            "proxy_pass_header Authorization;";
        };
      };
      "defaultDummy404ssl" = seashellSSL {
        default = true;
        serverName = "_";
        locations."/".extraConfig = "return 404;";
      };
    };
  };

  age.secrets.keycloakDBPassword.file = "${self}/secrets/keycloak_db.age";
  services.keycloak = {
    enable = false;
    settings.hostname = "https://test3.seashell.social/";
    database.passwordFile = config.age.secrets.keycloakDBPassword.path;
    settings.https-port = 23571;
  };

  system.stateVersion = "22.05";
}
