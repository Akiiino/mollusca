{
  config,
  self,
  ...
}: {
  config = {
    age.secrets.secondbrainNCPassword = {
      file = "${self}/secrets/secondbrain_nc_password.age";
      owner = "CTO";
      group = "CTO";
    };
    services.secondbrain.CTO = {
      enable = true;
      username = "akiiino";
      passwordFile = config.age.secrets.secondbrainNCPassword.path;
      calendarURL = "https://${config.services.nextcloud.hostName}/remote.php/dav/calendars/akiiino/daily-routine/";
      dayLookahead = 0;
    };
    systemd.services."CTO" = {
      requires = ["nginx.service" "phpfpm-nextcloud.service"];
      after = ["nginx.service" "phpfpm-nextcloud.service"];
    };
  };
}
