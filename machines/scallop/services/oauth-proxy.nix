{
  config,
  self,
  ...
}: {
  config = {
    age.secrets.oauth2_proxy.file = "${self}/secrets/oauth2-proxy.age";
    services.oauth2_proxy = {
      enable = true;
      keyFile = config.age.secrets.oauth2_proxy.path;
      cookie.domain = "." + self.secrets.personal_domain;

      provider = "nextcloud";
      loginURL = "https://${config.services.nextcloud.hostName}/apps/oauth2/authorize";
      redeemURL = "https://${config.services.nextcloud.hostName}/apps/oauth2/api/v1/token";
      validateURL = "https://${config.services.nextcloud.hostName}/ocs/v2.php/cloud/user?format=json";

      email.domains = ["*"];
      reverseProxy = true;
      httpAddress = "http://127.0.0.1:4180";
      nginx.virtualHosts = [config.services.nitter.server.hostname];

      extraConfig.whitelist-domain = "." + self.secrets.personal_domain;
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = self.secrets.personal_subdomain "oauth2";
      port = 4180;
    };
  };
}
