{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mollusca.eightbitdo;
in
{
  options.mollusca.eightbitdo.enable = lib.mkEnableOption "full support for 8BitDo gamepads";
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # 2.4GHz/Dongle
      KERNEL=="hidraw*", ATTRS{idVendor}=="2dc8", MODE="0660", TAG+="uaccess"
      # Bluetooth
      KERNEL=="hidraw*", KERNELS=="*2DC8:*", MODE="0660", TAG+="uaccess"
    '';
  };
}
