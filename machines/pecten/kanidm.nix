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
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  age.secrets.hetznerAPIKey.file = "${self}/secrets/hetzner.age";

  security.acme = {
    acceptTerms = true;
    certs.${config.domain} = {
      extraDomainNames = [ (config.mkSubdomain "*") ];
      email = minor-secrets.acmeEmail;
      dnsProvider = "hetzner";
      credentialsFile = config.age.secrets.hetznerAPIKey.path;
      webroot = null;
    };
  };
}
