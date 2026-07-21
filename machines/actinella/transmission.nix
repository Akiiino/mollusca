# Transmission (confined to ProtonVPN via services.transmissionConfined).
#
# Downloads land in /mnt/media/Seeding; on completion every file is hardlinked
# into /mnt/media/Staging so it can be reorganised while seeding continues.

{
  self,
  pkgs,
  lib,
  config,
  ...
}:

{
  age.secrets.proton-wireguard.file = "${self}/secrets/proton-wireguard.age";

  services.transmissionConfined = {
    enable = true;
    wireguardConfigFile = config.age.secrets.proton-wireguard.path;
    accessibleFrom = [ "192.168.1.0/24" ];
    settings = {
      download-dir = "/mnt/media/Seeding";
      script-torrent-done-enabled = true;
      script-torrent-done-filename = pkgs.writeShellScript "transmission-hardlink" ''
        set -euo pipefail
        cp -al "$TR_TORRENT_DIR/$TR_TORRENT_NAME" "/mnt/media/Staging/$TR_TORRENT_NAME"
      '';
    };
  };

  systemd.services.transmission.serviceConfig = {
    # because hardlinks can't span mount points BindPaths is mkForced to the
    # shared parent /mnt/media instead of the default path.
    BindPaths = lib.mkForce [
      "/var/lib/transmission/.config/transmission-daemon"
      "/run"
      "/var/lib/transmission/.incomplete"
      "/mnt/media"
    ];
    ReadWritePaths = [ "/var/lib/transmission" ];
  };
}
