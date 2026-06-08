{
  minor-secrets,
  ...
}:
{
  services.photoview = {
    enable = true;
    host = "0.0.0.0";
    port = 8300;
    mediaPath = "/var/lib/photoview/media";
    database.type = "sqlite";
    settings.mapboxToken = minor-secrets.mapboxToken;
  };

  # photo upload stuff
  systemd.tmpfiles.rules = [
    "d /var/lib/photoview/media 2770 photoview photoview -"
  ];

  users.users.builder.extraGroups = [ "photoview" ];
}
