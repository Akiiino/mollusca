{
  config,
  self,
  pkgs,
  ...
}: let
  cfg = config.services.keycloak;
in {
  config = {
    age.secrets.keycloakDBPass.file = "${self}/secrets/keycloak_db_pass.age";

    services.keycloak = {
      enable = true;
      database.passwordFile = config.age.secrets.keycloakDBPass.path;
      settings = {
        hostname = config.mkSubdomain "keycloak";
        hostname-strict-backchannel = true;
        proxy = "edge";
        http-host = "127.0.0.1";
        http-port = 37654;
        features = "declarative-user-profile";
        features-disabled = "kerberos,par";
      };
    };
    systemd.services."keycloak" = {
      requires = ["nginx.service"];
      after = ["nginx.service"];
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = cfg.settings.hostname;
      port = cfg.settings.http-port;
    };
  };
}
