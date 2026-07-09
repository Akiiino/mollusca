{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mollusca.gui;
in
{
  config = lib.mkIf (cfg.enable && cfg.desktopEnvironment == "plasma") {
    services = {
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
      desktopManager.plasma6.enable = true;
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      plasma-browser-integration
      konsole
      elisa
    ];
  };
}
