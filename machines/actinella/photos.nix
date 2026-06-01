{ ... }:
{
  services.photoview = {
    enable = true;
    host = "0.0.0.0";
    port = 8300;
    mediaPath = "/var/lib/photoview/media";
    database.type = "sqlite";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/photoview/media 0750 photoview photoview -"
  ];
}
