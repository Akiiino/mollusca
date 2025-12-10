{ config, pkgs, ... }:
let
  plasma-tv = pkgs.callPackage ./plasma-bigscreen.nix {
    kcmutils = pkgs.kdePackages.kcmutils;
    kdeclarative = pkgs.kdePackages.kdeclarative;
    ki18n = pkgs.kdePackages.ki18n;
    kio = pkgs.kdePackages.kio;
    knotifications = pkgs.kdePackages.knotifications;
    kwayland = pkgs.kdePackages.kwayland;
    kwindowsystem = pkgs.kdePackages.kwindowsystem;
    mkKdeDerivation = pkgs.kdePackages.mkKdeDerivation;
    qtmultimedia = pkgs.kdePackages.qtmultimedia;
    plasma-workspace = pkgs.kdePackages.plasma-workspace;
    bluez-qt = pkgs.kdePackages.bluez-qt;
    qtwebengine = pkgs.kdePackages.qtwebengine;
    plasma-nano = pkgs.kdePackages.plasma-nano;
    plasma-nm = pkgs.kdePackages.plasma-nm;
    milou = pkgs.kdePackages.milou;
    kscreen = pkgs.kdePackages.kscreen;
    kdeconnect-kde = pkgs.kdePackages.kdeconnect-kde;
    qtdeclarative = pkgs.kdePackages.qtdeclarative;
  };
  plasma-remotecontrollers = pkgs.callPackage ./plasma-remotecontrollers.nix {
    mkKdeDerivation = pkgs.kdePackages.mkKdeDerivation;
    qtbase = pkgs.kdePackages.qtbase;
    qtdeclarative = pkgs.kdePackages.qtdeclarative;
    qtwayland = pkgs.kdePackages.qtwayland;
    kconfig = pkgs.kdePackages.kconfig;
    kcoreaddons = pkgs.kdePackages.kcoreaddons;
    kdbusaddons = pkgs.kdePackages.kdbusaddons;
    kdeclarative = pkgs.kdePackages.kdeclarative;
    ki18n = pkgs.kdePackages.ki18n;
    kcmutils = pkgs.kdePackages.kcmutils;
    knotifications = pkgs.kdePackages.knotifications;
    kpackage = pkgs.kdePackages.kpackage;
    kwindowsystem = pkgs.kdePackages.kwindowsystem;
    kstatusnotifieritem = pkgs.kdePackages.kstatusnotifieritem;
    solid = pkgs.kdePackages.solid;
    plasma-workspace = pkgs.kdePackages.plasma-workspace;
    libplasma = pkgs.kdePackages.libplasma;
    plasma-wayland-protocols = pkgs.kdePackages.plasma-wayland-protocols;
    wayland = pkgs.wayland;
    libevdev = pkgs.libevdev;
    libcec = pkgs.libcec;
    xwiimote = null; # or pkgs.xwiimote if you want Wiimote support
  };
in
{
  xdg.portal.configPackages = [ plasma-tv ];
  services.displayManager.sessionPackages = [
    plasma-tv
  ];
  environment.systemPackages = [
    plasma-tv
    plasma-remotecontrollers
  ];
  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="input"
  '';
  # fixes homescreen not being focused after quiting app or on boot
  environment.plasma6.excludePackages = with pkgs; [
    # kdePackages.xwaylandvideobridge
  ];
  # services.displayManager.defaultSession = "plasma-bigscreen-wayland";
}
