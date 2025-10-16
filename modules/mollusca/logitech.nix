{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mollusca.logitech;
in
{
  options.mollusca.logitech.wireless.enable =
    lib.mkEnableOption "support for Logitech wireless devices";
  config = lib.mkIf cfg.wireless.enable {
    hardware.logitech.wireless.enable = true;
    systemd.user.services.solaar = {
      description = "Solaar, the open source driver for Logitech devices";
      wantedBy = [ "graphical-session.target" ];
      after = [ "dbus.service" ];
      environment = {
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.solaar "solaar"} --window hide";
        Restart = "on-failure";
        RestartSec = "5";
      };
    };
  };
}
