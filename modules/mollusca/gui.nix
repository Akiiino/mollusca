{
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

      (lib.mkIf (cfg.desktopEnvironment == "niri") {
        nixpkgs.overlays = [ inputs.niri.overlays.niri ];
        programs.niri.enable = true;

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };

        services = {
          displayManager = {
            sddm.enable = true;
            sddm.wayland.enable = true;
            defaultSession = "niri";
          };

          udev.packages = [ pkgs.swayosd ];
          blueman.enable = true;

          udisks2.enable = true; # USB automount
          gvfs.enable = true; # MTP, smb://, trash://, etc.
          tumbler.enable = true; # thumbnailer
          upower = {
            enable = true;
            criticalPowerAction = "Hibernate";
            percentageLow = 15;
            percentageCritical = 10;
            percentageAction = 5;
          };
        };

        # Essential packages for a usable niri desktop
        environment.systemPackages = with pkgs; [
          wl-clip-persist
          networkmanagerapplet
          playerctl
          pavucontrol
          fuzzel

          mako

          swayidle

          waybar

          xwayland-satellite

          kdePackages.dolphin
          kdePackages.ark
          kdePackages.breeze-icons

          adwaita-icon-theme
          gnome-themes-extra
        ];

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
          ];
          config.common = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };

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
