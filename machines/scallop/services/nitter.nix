{config, ...}: {
  services.nitter = {
    enable = true;
    server.hostname = "nitter." + config.minor_secrets.domain;
    server.address = "127.0.0.1";
    server.port = 13735;
    server.https = true;
  };
}
