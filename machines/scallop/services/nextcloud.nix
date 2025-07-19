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
      package = pkgs.nextcloud29;
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
      extraApps = {
        inherit
          (pkgs.nextcloud29Packages.apps)
          polls
          forms
          # unsplash
          calendar
          # files_texteditor
          # keeweb
          notes
          contacts
          tasks
          bookmarks
          deck
          groupfolders
          # oidc_login
          previewgenerator
          ;
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
          login_filter = "nextCloudGroups";
        };
        oidc_login_filter_allowed_values = ["nextcloud" "admin"];

        allow_user_to_change_display_name = false;
        lost_password_link = "disabled";
        oidc_login_default_quota = builtins.toString (100 * 1024 * 1024 * 1024);
        oidc_login_button_text = "Use Single-Sign-On";
        oidc_login_disable_registration = false;
        oidc_create_groups = true;
        oidc_login_hide_password_form = true;
        oidc_login_use_id_token = false;

        oidc_login_scope = "openid profile";

        oidc_login_webdav_enabled = false;
        oidc_login_password_authentication = true;

        oidc_login_public_key_caching_time = 86400;
        oidc_login_min_time_between_jwks_requests = 10;
        oidc_login_well_known_caching_time = 86400;

        oidc_login_update_avatar = false;

        oidc_login_skip_proxy = false;

        oidc_login_code_challenge_method = "S256";

        knowledgebaseenabled = false;

        preview_concurrency_all = 3;
        preview_concurrency_new = 1;
      };
    };

    age.secrets.nextcloudCifsPassword.file = "${self}/secrets/cifs_users/nextcloud.age";
    fileSystems.${cfg.datadir} = let
      username = config.mollusca.secrets.cifsUsers.nextcloud;
    in
      self.lib.mkCifs {
        location = "${username}.your-storagebox.de/${username}";
        uid = builtins.toString config.users.users.nextcloud.uid;
        gid = builtins.toString config.users.groups.nextcloud.gid;
        user = username;
        credentialsFile = config.age.secrets.nextcloudCifsPassword.path;
      };

    services.postgresql = {
      enable = true;
      ensureDatabases = lib.singleton cfg.config.dbname;
      ensureUsers = lib.singleton {
        name = cfg.config.dbuser;
        ensureDBOwnership = true;
      };
    };

    systemd.services."nextcloud-setup" = {
      requires = ["postgresql.service" "nginx.service"];
      after = ["postgresql.service" "nginx.service"];
    };

    services.nginx.virtualHosts = self.lib.mkVirtualHost {
      fqdn = cfg.hostName;
      vhostConfig.serverAliases = cfg.config.extraTrustedDomains;
    };
  };
}
