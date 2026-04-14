{ config, pkgs, ... }:
let
  plasma-tv = pkgs.callPackage ./plasma-bigscreen.nix {
    inherit (pkgs.kdePackages) kcmutils
    kdeclarative
    ki18n
    kio
    knotifications
    kwayland
    kwindowsystem
    mkKdeDerivation
    qtmultimedia
    plasma-workspace
    bluez-qt
    qtwebengine
    plasma-nano
    plasma-nm
    milou
    kscreen
    kdeconnect-kde
    qtdeclarative;
  };
  plasma-remotecontrollers = pkgs.callPackage ./plasma-remotecontrollers.nix {
    inherit (pkgs.kdePackages) mkKdeDerivation
    qtbase
    qtdeclarative
    qtwayland
    kconfig
    kcoreaddons
    kdbusaddons
    kdeclarative
    ki18n
    kcmutils
    knotifications
    kpackage
    kwindowsystem
    kstatusnotifieritem
    solid
    plasma-workspace
    libplasma
    plasma-wayland-protocols;
    inherit (pkgs) wayland
    libevdev
    libcec;
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
    # plasma-remotecontrollers
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
