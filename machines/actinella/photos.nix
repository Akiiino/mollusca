{ minor-secrets, ... }:
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

  mollusca.lanServices.services."photos.${minor-secrets.personalDomain}" = {
    proxyPass = "http://127.0.0.1:8300";
    websocket = true;
  };
}
