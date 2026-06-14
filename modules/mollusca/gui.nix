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
  options.mollusca.gui = {
    enable = lib.mkEnableOption "GUI";
    desktopEnvironment = lib.mkOption {
      type = lib.types.enum [
        "plasma"
        "niri"
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
              _: userConfig:
              (userConfig.password == null)
              && (userConfig.hashedPassword == null)
              && (userConfig.passwordFile == null)
            ) config.users.users
          );
        };
        networking.networkmanager.enable = true;
        fonts.packages = [
          pkgs.fira-code
          pkgs.nerd-fonts.hack
          pkgs.iosevka
          pkgs.noto-fonts
          pkgs.noto-fonts-color-emoji
          pkgs.noto-fonts-cjk-sans
        ];
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
    ]
  );
}
