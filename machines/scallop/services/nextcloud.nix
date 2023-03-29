{
  config,
  self,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.nextcloud;
in {
  config = {
    age.secrets.nextcloudRootPass = {
      file = "${self}/secrets/nextcloud_root_pass.age";
      owner = "nextcloud";
      group = "nextcloud";
    };
    age.secrets.nextcloudOidcSecret = {
      file = "${self}/secrets/nextcloud_oidc_secret.age";
      owner = "nextcloud";
      group = "nextcloud";
    };
    users.users.nextcloud.uid = 993;
    users.groups.nextcloud.gid = 992;
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud25;
      enableBrokenCiphersForSSE = false;
      hostName = config.mkSubdomain "nextcloud";
      home = "/persist/var/lib/nextcloud";
      datadir = "/persist/nextcloud_data";
      https = true;
      notify_push.enable = false;
      config = {
        dbtype = "pgsql";
        dbhost = "/run/postgresql";
        adminpassFile = config.age.secrets.nextcloudRootPass.path;
        defaultPhoneRegion = "DE";
        extraTrustedDomains = [(config.mkSubdomain "nc")];
        overwriteProtocol = "https";
      };
      phpOptions = {
        "opcache.memory_consumption" = "256";
        "opcache.interned_strings_buffer" = "128";
      };
      extraApps = with pkgs.nextcloud25Packages.apps; {
        inherit polls forms unsplash calendar deck files_texteditor keeweb notes contacts groupfolders tasks bookmarks;
        oidc_login = pkgs.fetchNextcloudApp rec {
          url = "https://github.com/pulsejet/nextcloud-oidc-login/releases/download/v2.4.1/oidc_login.tar.gz";
          sha256 = "sha256-muTtxUxhSvBbhmJuE/Aig2toLcg+62s/fyA5b73gkYE=";
        };
      };
      secretFile = config.age.secrets.nextcloudOidcSecret.path;
      extraOptions = {
        oidc_login_client_id = "nextcloud";
        oidc_login_provider_url = "https://${config.mkSubdomain "keycloak"}/realms/shore";
        oidc_login_end_session_redirect = true;
        oidc_login_logout_url = "https://${config.mkSubdomain "nextcloud"}/apps/oidc_login/oidc";
        oidc_login_auto_redirect = true;
        oidc_login_redir_fallback = true;
        oidc_login_attributes = {
          id = "preferred_username";
          mail = "email";
          name = "name";
          quota = "nextCloudQuota";
          groups = "nextCloudGroups";
        };

        allow_user_to_change_display_name = false;
        lost_password_link = "disabled";
        oidc_login_default_quota = builtins.toString (100 * 1024 * 1024 * 1024);
        oidc_login_button_text = "Use Single-Sign-On";
        oidc_login_disable_registration = false;
        oidc_create_groups = true;
        oidc_login_hide_password_form = true;
        oidc_login_use_id_token = false;

        #oidc_login_filter_allowed_values = [];

        oidc_login_scope = "openid profile";

        oidc_login_webdav_enabled = false;
        oidc_login_password_authentication = true;

        oidc_login_public_key_caching_time = 86400;
        oidc_login_min_time_between_jwks_requests = 10;
        oidc_login_well_known_caching_time = 86400;

        oidc_login_update_avatar = false;

        oidc_login_skip_proxy = false;

        oidc_login_code_challenge_method = "S256";
      };
    };

    age.secrets.nextcloudCifsPassword.file = "${self}/secrets/cifs_users/nextcloud.age";
    fileSystems.${cfg.datadir} = let
      username = config.secrets.cifsUsers.nextcloud;
      passwordFile = config.age.secrets.nextcloudCifsPassword.path;
      nextcloud_uid = builtins.toString config.users.users.nextcloud.uid;
      nextcloud_gid = builtins.toString config.users.groups.nextcloud.gid;
    in {
      device = "//${username}.your-storagebox.de/${username}";
      fsType = "cifs";
      options = [
        "user=${username}"
        "credentials=${passwordFile}"
        "seal"
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "uid=${nextcloud_uid}"
        "gid=${nextcloud_gid}"
        "file_mode=0750"
        "dir_mode=0750"
        "mfsymlinks"
      ];
    };

    services.postgresql = {
      ensureDatabases = [cfg.config.dbname];
      ensureUsers = lib.singleton {
        name = cfg.config.dbuser;
        ensurePermissions."DATABASE ${cfg.config.dbname}" = "ALL PRIVILEGES";
      };
    };

    systemd.services."nextcloud-setup" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };

    services.nginx.virtualHosts = self.lib.mkVirtualHost {
      fqdn = cfg.hostName;
      vhostConfig.serverAliases = cfg.config.extraTrustedDomains;
      # }
      # // self.lib.mkVirtualHost {
      #   fqdn = config.mkSubdomain "nc";
      #   vhostConfig.globalRedirect = cfg.hostName;
    };
  };
}
