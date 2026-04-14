{
  self,
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  minor-secrets,
  ...
}:
{
  services.tailscale.derper = {
    enable = true;
    domain = "${minor-secrets.derpDomain}";
    verifyClients = true;
  };

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
      group = "nginx";
      dnsResolver = "1.1.1.1:53";
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx.virtualHosts."${minor-secrets.derpDomain}" = {
    useACMEHost = minor-secrets.personalDomain;
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
