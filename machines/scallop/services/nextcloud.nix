{
  config,
  self,
  pkgs,
  ...
}: {
  config = {
    age.secrets.nextcloudRootPass = {
      file = "${self}/secrets/nextcloud_root_pass.age";
      owner = "nextcloud";
      group = "nextcloud";
    };
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud25;
      enableBrokenCiphersForSSE = false;
      hostName = self.secrets.personal_subdomain "nextcloud";
      https = true;
      notify_push.enable = false;
      config = {
        dbtype = "pgsql";
        dbuser = "nextcloud";
        # dbpassFile = "";  # TODO: add
        dbhost = "/run/postgresql";
        dbname = "nextcloud";
        adminuser = "root";
        adminpassFile = config.age.secrets.nextcloudRootPass.path;
        defaultPhoneRegion = "DE";
      };
      phpOptions = {
        "opcache.memory_consumption" = "256";
        "opcache.interned_strings_buffer" = "128";
      };
      extraApps = with pkgs.nextcloud25Packages.apps; {
        inherit polls forms unsplash calendar deck files_texteditor keeweb notes contacts groupfolders tasks bookmarks;
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = ["nextcloud"];
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
        }
      ];
    };

    systemd.services."nextcloud-setup" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };

    services.nginx.virtualHosts =
      self.lib.mkVirtualHost {
        fqdn = config.services.nextcloud.hostName;
      }
      // self.lib.mkVirtualHost {
        fqdn = self.secrets.personal_subdomain "nc";
        vhostConfig.globalRedirect = config.services.nextcloud.hostName;
      };
  };
}
