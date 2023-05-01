{
  config,
  self,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.calibre-web;
  fqdn = config.mkSubdomain "calibre";
in {
  config = {
    environment.persistence."/persist".directories = lib.singleton {
      inherit (cfg) user group;
      directory = "/var/lib/" + cfg.dataDir;
      mode = "u=rwx,g=rx,o=";
    };

    services.calibre-web = {
      enable = true;
      listen = {
          ip = "127.0.0.1";
          port = 44536;
      };
      options = {
        enableBookUploading = true;
        reverseProxyAuth = {
            enable = true;
            header = "X-Auth-User";
        };
      };
    };

    services.nginx.virtualHosts = self.lib.mkProxy {
      inherit fqdn;
      port = cfg.listen.port;
    };

    systemd.services."calibre-web" = {
      requires = ["nginx.service"];
      after = ["nginx.service"];
    };

    services.oauth2_proxy.nginx.virtualHosts = lib.singleton fqdn;
  };
}

