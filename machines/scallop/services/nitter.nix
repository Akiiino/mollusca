{
  config,
  self,
  ...
}: {
  config.services = {
    nitter = {
      enable = true;
      server.hostname = self.secrets.personal_subdomain "nitter";
      server.address = "127.0.0.1";
      server.port = 13735;
      server.https = true;
    };
    nginx.virtualHosts = self.lib.mkProxy {
      fqdn = config.services.nitter.server.hostname;
      port = config.services.nitter.server.port;
    };
  };
}
