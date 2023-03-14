{
  config,
  lib,
  ...
}: {
  config.services = {
    nitter = {
      enable = true;
      server.hostname = "nitter." + config.minor_secrets.public_domain;
      server.address = "127.0.0.1";
      server.port = 13735;
      server.https = true;
    };
    nginx.virtualHosts = {
      "nitter.${config.minor_secrets.public_domain}" = {
        useACMEHost = config.minor_secrets.public_domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:13735";
          proxyWebsockets = true;
          extraConfig =
            "proxy_ssl_server_name on;"
            + "proxy_pass_header Authorization;";
        };
      };
      "nitter.${config.minor_secrets.private_domain}" = {
        useACMEHost = config.minor_secrets.private_domain;
        forceSSL = true;
        globalRedirect = "nitter.${config.minor_secrets.public_domain}";
      };
    };
  };
}
