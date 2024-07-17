{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.gitea;
  domain = config.mkSubdomain "git";
  port = 16156;
in {
  config = {
    services.gitea = {
      inherit domain;
      enable = true;
      database.type = "postgres";
      httpAddress = "127.0.0.1";
      httpPort = port;
      rootUrl = "https://${cfg.domain}";
      settings = {
        service = {DISABLE_REGISTRATION = true;};
        session = {COOKIE_SECURE = true;};
      };
      stateDir = "/persist/gitea";
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      inherit port;
      fqdn = domain;
    };

    #services.oauth2-proxy.nginx.virtualHosts = lib.singleton domain;
  };
}
