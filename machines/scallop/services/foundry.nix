{
  config,
  self,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.foundryvtt;
in
{
  imports = [
    self.inputs.foundryvtt.nixosModules.foundryvtt
  ];
  config = {
    age.secrets.keycloakDBPass.file = "${self}/secrets/keycloak_db_pass.age";

    services.foundryvtt = {
      enable = true;
      hostName = "foundry.seashell.social";
      minifyStaticFiles = true;
      proxyPort = 443;
      proxySSL = true;
      upnp = false;
      port = 61124;
      # dataDir = "/persist/var/lib/foundryvtt";
      package = self.inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_12;
    };
    #systemd.services."keycloak" = {
    #  requires = ["nginx.service"];
    #  after = ["nginx.service"];
    #};

    environment.persistence."/persist".directories = lib.singleton {
      directory = "/var/lib/foundryvtt";
      user = "foundryvtt";
      group = "foundryvtt";
      mode = "u=rwx,g=,o=";
    };
    services.nginx.virtualHosts = self.lib.mkProxy {
      fqdn = cfg.hostName;
      port = cfg.port;
    };
  };
}
