{
  self,
  config,
  lib,
  minor-secrets,
  ...
}:
{
  options.mollusca = {
    useDefaultDomain = lib.mkEnableOption "default domain configuration";
  };
  config = lib.mkIf config.mollusca.useDefaultDomain {
    age.secrets.acmeDns.file = "${self}/secrets/acme-dns.age";

    security.acme = {
      acceptTerms = true;
      defaults.email = minor-secrets.acmeEmail;
      certs."${minor-secrets.personalDomain}" = {
        domain = minor-secrets.personalDomain;
        extraDomainNames = [ "*.${minor-secrets.personalDomain}" ];
        dnsProvider = "hetzner";
        dnsPropagationCheck = true;
        environmentFile = config.age.secrets.acmeDns.path;
        group = "acme";
        dnsResolver = "1.1.1.1:53";
      };
    };
  };
}

