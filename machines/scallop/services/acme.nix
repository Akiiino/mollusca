{
  config,
  self,
  ...
}: {
  config = {
    security.acme.acceptTerms = true;
    age.secrets.hetznerAPIKey.file = "${self}/secrets/hetzner.age";
    security.acme.defaults = {
      email = self.secrets.acme_email;
      dnsProvider = "hetzner";
      credentialsFile = config.age.secrets.hetznerAPIKey.path;
      webroot = null;
    };
    security.acme.certs = {
      "${self.secrets.personal_domain}".extraDomainNames = [(self.secrets.personal_subdomain "*")];
      "${self.secrets.public_domain}".extraDomainNames = [(self.secrets.public_subdomain "*")];
    };
  };
}
