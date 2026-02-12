{
  self,
  config,
  pkgs,
  lib,
  inputs,
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
        networking.networkmanager.enable = true;
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

      (lib.mkIf (cfg.desktopEnvironment == "niri") {
        nixpkgs.overlays = [ inputs.niri.overlays.niri ];
        programs.niri.enable = true;

        services.displayManager = {
          sddm.enable = true;
          sddm.wayland.enable = true;
          defaultSession = "niri";
        };

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };
        services.udev.packages = [ pkgs.swayosd ];
        services.blueman.enable = true;
        services.upower.enable = true;

        # Essential packages for a usable niri desktop
        environment.systemPackages = with pkgs; [
          networkmanagerapplet
          playerctl
          pavucontrol
          fuzzel

          mako

          swaylock
          swayidle

          waybar

          xwayland-satellite

          nautilus

          adwaita-icon-theme
          gnome-themes-extra
        ];

        security.polkit.enable = true;
        systemd.user.services.polkit-agent = {
          description = "Polkit Authentication Agent";
          wantedBy = [ "graphical-session.target" ];
          wants = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
            Restart = "on-failure";
            RestartSec = 1;
            TimeoutStopSec = 10;
          };
        };
      })
    ]
  );
}
