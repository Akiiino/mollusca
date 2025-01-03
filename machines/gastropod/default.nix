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

  mollusca.gui = {
    enable = true;
    desktopEnvironment = "gnome";
  };
  mollusca.isRemote = true;
  mollusca.enableHM = true;

  services.thermald.enable = true;

  services.printing.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.gnome.core-utilities.enable = false;
  environment.systemPackages = with pkgs; [
    gparted
    gnome.eog
    gnome.evince
    gnome.nautilus
    gnome.totem
    gnome.gnome-bluetooth
    gnome.gnome-calculator
    gnome.gnome-screenshot
    gnome.file-roller
    gnome.gnome-clocks
    gnome.gnome-music
    gnome.gnome-tweaks
    gnome-photos
    gnome.gnome-calendar
    gnome.gnome-power-manager
    gedit
    gnome.cheese
    gnome.dconf-editor
    gnome.gnome-remote-desktop
  ];
  environment.gnome.excludePackages = with pkgs; [gnome-tour];

  programs = {
    steam.enable = true;
    zsh.enable = true;
    adb.enable = true;
  };
  networking.firewall.allowedTCPPorts = [5000 53317];
  networking.firewall.allowedUDPPorts = [34197 53317];
}
