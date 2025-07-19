{self, ...}: let
  lib = self.inputs.nixpkgs.lib;
in rec {
  mkVirtualHost = {
    fqdn,
    vhostConfig ? {},
  }: let
    domain = builtins.concatStringsSep "." (self.lib.takeLast 2 (lib.splitString "." fqdn));
  in {
    "${fqdn}" =
      {
        forceSSL = true;
        enableACME = lib.mkForce false;
        useACMEHost = domain;
      }
      // vhostConfig;
  };

  mkProxy = {
    fqdn,
    port,
    extraConfig ? "",
    extraVhostConfig ? {},
  }:
    mkVirtualHost {
      inherit fqdn;
      vhostConfig =
        {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString port}";
            proxyWebsockets = true;
            extraConfig =
              ''
                proxy_pass_header Authorization;
                proxy_busy_buffers_size 512k;
                proxy_buffers 4 512k;
                proxy_buffer_size 256k;
              ''
              + extraConfig;
          };
        }
        // extraVhostConfig;
    };

  mkCifs = {
    uid,
    gid,
    location,
    user ? "nobody",
    credentialsFile ? null,
    file_mode ? "0700",
    dir_mode ? "0700",
  }: {
    device = "//${location}";
    fsType = "cifs";
    options =
      [
        "user=${user}"
        "seal"
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "uid=${builtins.toString uid}"
        "gid=${builtins.toString gid}"
        "file_mode=${file_mode}"
        "dir_mode=${dir_mode}"
        "mfsymlinks"
      ]
      ++ lib.optional (credentialsFile != null) "credentials=${credentialsFile}";
  };
}
