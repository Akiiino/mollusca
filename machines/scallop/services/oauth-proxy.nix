{
  config,
  self,
  lib,
  ...
}: {
  imports = [./oauth-proxy_nginx.nix];
  config = {
    age.secrets.oauth2_proxy.file = "${self}/secrets/oauth2-proxy_keycloak.age";
    services.oauth2_proxy = {
      enable = true;
      keyFile = config.age.secrets.oauth2_proxy.path;
      cookie.domain = "." + config.domain;
      cookie.expire = "336h0m0s";

      provider = "keycloak-oidc";
      redirectURL = "https://${config.mkSubdomain "oauth2"}/oauth2/callback";

      email.domains = ["*"];
      reverseProxy = true;
      httpAddress = "http://127.0.0.1:4180";

      extraConfig.whitelist-domain = "." + config.domain;
      extraConfig.oidc-issuer-url = "https://${config.services.keycloak.settings.hostname}/realms/shore";
    };
    systemd.services."oauth2_proxy" = {
      requires = ["keycloak.service"];
      after = ["keycloak.service"];
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = config.mkSubdomain "oauth2";
      port = 4180;
    };
  };
}
