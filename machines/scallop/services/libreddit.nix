{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.libreddit;
  hostname = config.mkSubdomain "libreddit";
  port = 13736;
in {
  config = {
    services.libreddit = {
      inherit port;
      enable = true;
      address = "127.0.0.1";
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      inherit port;
      fqdn = hostname;
    };

    services.oauth2_proxy.nginx.virtualHosts = lib.singleton hostname;
  };
}
