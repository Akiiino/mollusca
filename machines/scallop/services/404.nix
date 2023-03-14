{config, ...}: {
  config.services.nginx.virtualHosts = {
    "${config.minor_secrets.private_domain}" = {
      locations."/".extraConfig = "return 404;";
      enableACME = true;
      forceSSL = true;
    };
    "${config.minor_secrets.public_domain}" = {
      locations."/".extraConfig = "return 404;";
      enableACME = true;
      forceSSL = true;
    };
    "*.${config.minor_secrets.private_domain}" = {
      locations."/".extraConfig = "return 404;";
      useACMEHost = config.minor_secrets.private_domain;
      forceSSL = true;
    };
    "*.${config.minor_secrets.public_domain}" = {
      locations."/".extraConfig = "return 404;";
      useACMEHost = config.minor_secrets.public_domain;
      forceSSL = true;
    };
  };
}
