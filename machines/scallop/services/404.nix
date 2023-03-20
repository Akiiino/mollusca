{
  config,
  self,
  ...
}: {
  config.services.nginx.virtualHosts = {
    "${self.secrets.personal_domain}" = {
      locations."/".extraConfig = "return 404;";
      enableACME = true;
      forceSSL = true;
    };
    "${self.secrets.public_domain}" = {
      locations."/".extraConfig = "return 404;";
      enableACME = true;
      forceSSL = true;
    };
    "${self.secrets.personal_subdomain "*"}" = {
      locations."/".extraConfig = "return 404;";
      useACMEHost = self.secrets.personal_domain;
      forceSSL = true;
    };
    "${self.secrets.public_subdomain "*"}" = {
      locations."/".extraConfig = "return 404;";
      useACMEHost = self.secrets.public_domain;
      forceSSL = true;
    };
  };
}
