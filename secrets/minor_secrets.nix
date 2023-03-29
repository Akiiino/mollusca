{
  config,
  lib,
  self,
  ...
}: let
  raw_secrets =
    lib.importJSON "${self}/secrets/minor_secrets.json";
in {
  options.secrets = {
    acmeEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email used for ACME secrificates";
      default = raw_secrets.acme_email;
      readOnly = true;
    };
    personalDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain used for personal services";
      default = raw_secrets.personal_domain;
      readOnly = true;
    };
    publicDomain = lib.mkOption {
      type = lib.types.str;
      description = "Domain used for public or shared services";
      default = raw_secrets.public_domain;
      readOnly = true;
    };
    cifsUsers = lib.genAttrs ["nextcloud"] (name:
      lib.mkOption {
        type = lib.types.str;
        description = "CIFS user for service `${name}`";
        default = raw_secrets.cifs_users.${name};
        readOnly = true;
      });
  };
}
