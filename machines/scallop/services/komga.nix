{
  config,
  self,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.komga;
  configFile = pkgs.writeTextDir "application.yml" (builtins.toJSON cfg.settings);
in {
  options = {
    services.komga.settings = lib.mkOption {
      type = with lib.types; attrs;
      default = {};
    };
  };
  config = {
    environment.persistence."/persist".directories = lib.singleton {
      directory = cfg.stateDir;
      user = cfg.user;
      group = cfg.group;
      mode = "u=rwx,g=rx,o=";
    };
    # networking.firewall.allowedTCPPorts = [18810];
    services.komga = {
      enable = true;
      port = 18810;
      settings = {
        komga.oauth2-account-creation = true;
        spring.security.oauth2.client = {
          registration.keycloak = {
            provider = "keycloak";
            client-id = "komga";
            client-secret = "@secret@";
            client-name = "Keycloak";
            scope = "openid,email";
            authorization-grant-type = "authorization_code";
            redirect-uri = "{baseUrl}/{action}/oauth2/code/{registrationId}";
          };
          provider.keycloak = {
            user-name-attribute = "sub";
            issuer-uri = "https://${config.mkSubdomain "keycloak"}/realms/shore";
            #authorization-uri = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/auth";
            #token-uri = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/token";
            #jwk-set-uri = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/certs";
            #user-info-uri = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/userinfo";
          };
        };
      };
    };
    age.secrets.komgaClientSecret = {
      file = "${self}/secrets/komga_client_secret.age";
      owner = "komga";
      group = "komga";
    };
    systemd.services.komga.serviceConfig.ExecStartPre = pkgs.writers.writePython3 "komga-prestart" {} ''
      import os

      stateDir = "${cfg.stateDir}"
      configFile = "${configFile}"
      os.makedirs(stateDir, mode=0o750, exist_ok=True)

      with open("${config.age.secrets.komgaClientSecret.path}", "r") as f:
          secret = f.read().strip()
      with open(f"{configFile}/application.yml", "r") as f_in:
          with open(f"{stateDir}/application.yml", "w") as f_out:
              f_out.write(f_in.read().replace("@secret@", secret))
    '';

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = config.mkSubdomain "komga";
      port = cfg.port;
    };

    services.oauth2_proxy.nginx.virtualHosts = lib.singleton (config.mkSubdomain "komga");
  };
}
