{
  config,
  self,
  lib,
  ...
}: {
  config = {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts = {
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
    };
  };
}
