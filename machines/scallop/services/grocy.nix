{
  config,
  self,
  ...
}: {
  config.services = {
    grocy = {
      enable = true;
      hostName = self.secrets.personal_subdomain "grocynew";
      settings = {
        currency = "EUR";
        culture = "en_GB";
        calendar.firstDayOfWeek = 1;
      };
    };
    nginx.virtualHosts = self.lib.mkVirtualHost {
      fqdn = config.services.grocy.hostName;
    };
  };
}
