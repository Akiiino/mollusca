{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.invidious;
in {
  config = {
    services.invidious = {
      enable = true;
      domain = config.mkSubdomain "invidious";
      port = 18510;
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = cfg.server.hostname;
      port = cfg.server.port;
    };

    services.oauth2-proxy.nginx.virtualHosts = lib.singleton cfg.server.hostname;
  };
}
