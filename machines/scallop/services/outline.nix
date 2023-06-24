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

    age.secrets.outlineCredentials = {
        file = "${self}/secrets/outline.age";
        owner = "outline";
        group = "outline";
    };
    age.secrets.outlineOIDCCredentials = {
        file = "${self}/secrets/outline_OIDC.age";
        owner = "outline";
        group = "outline";
    };
    services.outline = {
      enable = true;
      secretKeyFile = "/persist/var/lib/outline/secret_key";
      utilsSecretFile = "/persist/var/lib/outline/utils_secret";
      publicUrl = "https://" + config.mkSubdomain "outline";
      port = 42511;
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
      fqdn = config.mkSubdomain "outline";
      port = cfg.port;
    };
  };
}
