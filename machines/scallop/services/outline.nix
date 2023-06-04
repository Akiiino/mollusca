{
  config,
  self,
  pkgs,
  ...
}: let
  cfg = config.services.outline;
in {
  config = {
    age.secrets.keycloakDBPass = {
      file = "${self}/secrets/keycloak_db_pass.age";
    };

    age.secrets.outlineCredentials.file = "${self}/secrets/outline.age";
    age.secrets.outlineOIDCCredentials.file = "${self}/secrets/outline_OIDC.age";
    services.outline = {
      enable = false;
      secretKeyFile = "/persist/var/lib/outline/secret_key";
      utilsSecretFile = "/persist/var/lib/outline/utils_secret";
      publicUrl = config.mkSubdomain "outline";
      port = 42510;
      storage = {
        accessKey = "l7nGG60kqXIwazeIKcfn";
        secretKeyFile = config.age.secrets.outlineCredentials.path;
        region = "eu-west-1";
        uploadBucketUrl = "https://" + (config.mkSubdomain "minio");
        uploadBucketName = "outline";
      };
      oidcAuthentication = {
        clientId = "outline";
        clientSecretFile = config.age.secrets.outlineOIDCCredentials.path;
        authUrl = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/auth";
        tokenUrl = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/token";
        userinfoUrl = "https://${config.mkSubdomain "keycloak"}/realms/shore/protocol/openid-connect/userinfo";
      };
    };
    systemd.services."outline" = {
      requires = ["minio.service"];
      after = ["minio.service"];
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = cfg.publicUrl;
      port = cfg.port;
    };
  };
}
