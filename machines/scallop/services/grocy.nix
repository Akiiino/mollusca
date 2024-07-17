{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.grocy;
in {
  config = {
    services.grocy = {
      enable = true;
      hostName = "grocy.localhost";
      settings = {
        currency = "EUR";
        culture = "en_GB";
        calendar.firstDayOfWeek = 1;
      };
      nginx.enableSSL = false;
      dataDir = "/persist/var/lib/grocy";
    };
    services.nginx.virtualHosts =
      {
        ${cfg.hostName}.listen = lib.singleton {
          addr = "127.0.0.1";
          port = 35168;
        };
      }
      // self.lib.mkProxy {
        fqdn = config.mkSubdomain "grocy";
        port = 35168;
      };
    systemd.services."grocy" = {
      requires = ["nginx.service"];
      after = ["nginx.service"];
    };
    services.oauth2-proxy.nginx.virtualHostsWithGroups = lib.singleton {
      vhost = config.mkSubdomain "grocy";
      groups = ["family"];
    };
  };
}
