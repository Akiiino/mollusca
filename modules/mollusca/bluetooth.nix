{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mollusca.bluetooth;
in
{
  options.mollusca.bluetooth.enable = lib.mkEnableOption "Bluetooth";
  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
  };
}
