{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.security.acme;
in {
  config = {
    environment.persistence."/persist".directories = lib.singleton {
      directory = "/var/lib/acme";
      user = "acme";
      group = "acme";
      mode = "u=rwx,g=rx,o=";
    };

    age.secrets.hetznerAPIKey.file = "${self}/secrets/hetzner.age";

    security.acme = {
      acceptTerms = true;
      certs.${config.domain} = {
        extraDomainNames = [(config.mkSubdomain "*")];
        email = config.secrets.acmeEmail;
        dnsProvider = "hetzner";
        credentialsFile = config.age.secrets.hetznerAPIKey.path;
        webroot = null;
      };
    };
  };
}
