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
  config = lib.mkIf (cfg.enable && cfg.desktopEnvironment == "niri") {
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

    environment.systemPackages = with pkgs; [
      xwayland-satellite

      kdePackages.breeze-icons
      adwaita-icon-theme
      gnome-themes-extra
    ];

    # programs.niri.enable already enables the portal, adds the gnome portal, and
    # registers niri's bundled niri-portals.conf (which sets default=gnome;gtk and
    # routes Access/Notification to gtk). It does NOT set a FileChooser preference,
    # so we add the gtk portal and force the gtk file chooser here.
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common."org.freedesktop.impl.portal.FileChooser" = "gtk";
    };
  };
}
