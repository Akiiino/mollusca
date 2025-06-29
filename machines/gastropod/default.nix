{
  config,
  pkgs,
  lib,
  self,
  ...
}: {
  imports = [
    self.inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
    ./hardware-configuration.nix
    "${self}/users/akiiino"
  ];
  fonts.packages = [
    pkgs.fira-code
    pkgs.nerd-fonts.hack
    pkgs.iosevka
  ];

  users.users.akiiino = {
    extraGroups = ["adbusers"];
    hashedPassword = "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
  };
  nix.settings.auto-optimise-store = true;
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "gastropod";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  mollusca.gui = {
    enable = true;
    desktopEnvironment = "gnome";
  };
  mollusca.isRemote = true;
  mollusca.enableHM = true;

  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  services.thermald.enable = true;

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.gnome.core-utilities.enable = false;
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    gparted
    eog
    evince
    nautilus
    totem
    gnome-bluetooth
    gnome-calculator
    gnome-screenshot
    file-roller
    gnome-clocks
    gnome-music
    gnome-tweaks
    gnome-photos
    gnome-calendar
    gnome-power-manager
    gedit
    cheese
    dconf-editor
    gnome-remote-desktop
  ];
  environment.gnome.excludePackages = with pkgs; [gnome-tour];

  programs = {
    steam.enable = true;
    zsh.enable = true;
    adb.enable = true;
  };
  networking.firewall.allowedTCPPorts = [5000 53317];
  networking.firewall.allowedUDPPorts = [34197 53317];

  services.xserver.wacom.enable = true;
  services.fwupd.enable = true;
}
