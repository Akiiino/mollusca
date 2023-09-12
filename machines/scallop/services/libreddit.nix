{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.libreddit;
  fqdn = config.mkSubdomain "libreddit";
  port = 13736;
in {
  config = {
    services.libreddit = {
      inherit port;
      enable = true;
      address = "127.0.0.1";
    };

    services.nginx.virtualHosts = self.lib.mkProxy {inherit port fqdn;};

    systemd.services."libreddit" = {
      requires = ["nginx.service"];
      after = ["nginx.service"];
    };

    services.oauth2_proxy.nginx.virtualHosts = lib.singleton fqdn;
  };
}
