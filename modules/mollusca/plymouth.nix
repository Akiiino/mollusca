{
  self,
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
  cfg = config.mollusca.plymouth;
in
{
  options.mollusca.plymouth.enable = lib.mkEnableOption "Plymouth";
  config = lib.mkIf cfg.enable {
    boot = {
      plymouth.enable = true;
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];
      loader.timeout = 0;
    };
  };
}
