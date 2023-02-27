{ lib, self, ... }: {
  options.minor_secrets = lib.mkOption {
    type = lib.types.attrs;
    default = lib.importJSON "${self}/secrets/minor_secrets.json";
    readOnly = true;
  };
}
