# Kanidm identity-management server.
#
# Kanidm terminates its own TLS on the IPv6 loopback (it refuses to run
# plaintext); nginx fronts it at https://idm.<personalDomain> using the shared
# ACME wildcard cert. Single origin, because Kanidm ties WebAuthn/OAuth2 to one
# origin and a rename invalidates all credentials.

{
  self,
  config,
  lib,
  pkgs,
  minor-secrets,
  ...
}:
let
  host = "idm.${minor-secrets.personalDomain}";
  acmeDir = config.security.acme.certs.${minor-secrets.personalDomain}.directory;
in
{
  services.kanidm = {
    package = pkgs.kanidm_1_10.withSecretProvisioning;
    server.enable = true;
    server.settings = {
      bindaddress = "[::1]:8443";
      origin = "https://${host}";
      domain = host;
      tls_chain = "${acmeDir}/fullchain.pem";
      tls_key = "${acmeDir}/key.pem";
      http_client_address_info."x-forward-for" = [
        "::1"
        "127.0.0.1"
      ];
    };
    provision = {
      enable = true;
      idmAdminPasswordFile = config.age.secrets.kanidm-idm-admin.path;
      groups."mollusca_users" = { };
      persons.akiiino = {
        displayName = minor-secrets.name;
        mailAddresses = [ minor-secrets.acmeEmail ];
        groups = [ "mollusca_users" ];
      };
    };
  };

  age.secrets.kanidm-idm-admin = {
    file = "${self}/secrets/kanidm-idm-admin.age";
    owner = "kanidm";
    group = "kanidm";
    mode = "0400";
  };

  # Kanidm reads the cert/key directly and must restart to pick up renewals.
  users.users.kanidm.extraGroups = [ "acme" ];
  security.acme.certs.${minor-secrets.personalDomain}.reloadServices = [ "kanidm.service" ];

  services.nginx.virtualHosts.${host} = {
    forceSSL = true;
    useACMEHost = minor-secrets.personalDomain;
    locations."/" = {
      proxyPass = "https://[::1]:8443";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
