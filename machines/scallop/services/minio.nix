{
  config,
  self,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.minio;
in {
  config = {
    age.secrets.keycloakDBPass = {
      file = "${self}/secrets/keycloak_db_pass.age";
    };

    age.secrets.minioRootCredentials.file = "${self}/secrets/minio.age";
    services.minio = {
      enable = true;
      listenAddress = ":9000";
      consoleAddress = ":6129";
      dataDir = lib.singleton "/persist/minio_data";
      configDir = "/persist/var/lib/minio";
      rootCredentialsFile = config.age.secrets.minioRootCredentials.path;
      region = "eu-west-1";
    };

    age.secrets.minioCifsPassword.file = "${self}/secrets/cifs_users/minio.age";
    fileSystems.${builtins.head cfg.dataDir} = let
      username = config.mollusca.secrets.cifsUsers.minio;
      passwordFile = config.age.secrets.minioCifsPassword.path;
      minio_uid = builtins.toString config.users.users.minio.uid;
      minio_gid = builtins.toString config.users.groups.minio.gid;
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
        "uid=${minio_uid}"
        "gid=${minio_gid}"
        "file_mode=0750"
        "dir_mode=0750"
        "mfsymlinks"
      ];
    };

    services.nginx.virtualHosts =
      self.lib.mkProxy {
        fqdn = config.mkSubdomain "minio-console";
        port = lib.toInt (builtins.substring 1 6 cfg.consoleAddress);
      }
      // self.lib.mkProxy {
        fqdn = config.mkSubdomain "minio";
        port = lib.toInt (builtins.substring 1 6 cfg.listenAddress);
      };
  };
}
