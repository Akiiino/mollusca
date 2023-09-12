{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.mollusca.gui;
in {
  options.mollusca.gui = {
    enable = lib.mkEnableOption "GUI";
    desktopEnvironment = lib.mkOption {
      type = lib.types.enum ["gnome" "plasma"];
      description = "What desktop environment to use.";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.xserver = {
          enable = true;
          excludePackages = [pkgs.xterm];
          displayManager.hiddenUsers = builtins.attrNames (
            lib.filterAttrs (
              name: userConfig:
                (userConfig.password == null)
                && (userConfig.hashedPassword == null)
                && (userConfig.passwordFile == null)
            )
            config.users.users
          );
        };
      }
      (lib.mkIf (cfg.desktopEnvironment == "plasma") {
        services.xserver = {
          displayManager.sddm.enable = true;
          desktopManager.plasma5.enable = true;
        };
      })
      (lib.mkIf (cfg.desktopEnvironment == "gnome") {
        services.xserver = {
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
        };
      })
    ]
  );
}
