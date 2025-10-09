{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mollusca.gui;
in
{
  options.mollusca.gui = {
    enable = lib.mkEnableOption "GUI";
    desktopEnvironment = lib.mkOption {
      type = lib.types.enum [
        "gnome"
        "plasma"
      ];
      description = "What desktop environment to use.";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services = {
          displayManager.hiddenUsers = builtins.attrNames (
            lib.filterAttrs (
              name: userConfig:
              (userConfig.password == null)
              && (userConfig.hashedPassword == null)
              && (userConfig.passwordFile == null)
            ) config.users.users
          );
          xserver = {
            # enable = true;
            # excludePackages = [pkgs.xterm];
          };
        };
      }
      (lib.mkIf (cfg.desktopEnvironment == "plasma") {
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
      })
      (lib.mkIf (cfg.desktopEnvironment == "gnome") {
        services = {
          xserver.displayManager.gdm.enable = true;
          xserver.desktopManager.gnome.enable = true;
        };
      })
    ]
  );
}
