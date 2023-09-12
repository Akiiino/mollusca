{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.nitter;
in {
  config = {
    services.nitter = {
      enable = true;
      server.hostname = config.mkSubdomain "nitter";
      server.address = "127.0.0.1";
      server.port = 13735;
      server.https = true;
    };

    systemd.services."nitter" = {
      requires = ["nginx.service"];
      after = ["nginx.service"];
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = cfg.server.hostname;
      port = cfg.server.port;
    };

    services.oauth2_proxy.nginx.virtualHosts = lib.singleton cfg.server.hostname;
  };
}
