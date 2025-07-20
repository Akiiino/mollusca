{
  config,
  self,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.postgresql;
in
{
  config = {
    environment.persistence."/persist".directories = lib.singleton {
      directory = cfg.dataDir;
      user = "postgres";
      group = "postgres";
      mode = "u=rwx,g=rx,o=";
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
    };
  };
}
