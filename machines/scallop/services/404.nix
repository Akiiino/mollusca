{
  config,
  self,
  ...
}: {
  config.services.nginx.virtualHosts = {
    "${config.domain}" = {
      locations."/".extraConfig = "return 404;";
      enableACME = true;
      forceSSL = true;
    };
    "${config.mkSubdomain "*"}" = {
      locations."/".extraConfig = "return 404;";
      useACMEHost = config.domain;
      forceSSL = true;
    };
  };
}
