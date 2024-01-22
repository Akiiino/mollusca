{
  config,
  pkgs,
  lib,
  self,
  ...
}: {
  imports = [
    self.inputs.nixos-hardware.nixosModules.framework
    ./hardware-configuration.nix
    "${self}/users/akiiino"
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
    gnome.gedit
    gnome.cheese
    gnome.dconf-editor
    gnome.gnome-remote-desktop
  ];
  environment.gnome.excludePackages = with pkgs; [gnome-tour];

  programs.steam.enable = true;

  programs.adb.enable = true;
  networking.firewall.allowedTCPPorts = [5000];
  networking.firewall.allowedUDPPorts = [34197];

  services.interception-tools = let
    dualFunctionFile = pkgs.writeText "dual-function-keys.yaml" ''
      MAPPINGS:
        - KEY: KEY_MEDIA
          TAP: KEY_DELETE
          HOLD: KEY_DELETE
          HOLD_START: BEFORE_CONSUME
    '';
  in {
    enable = true;
    plugins = [pkgs.interception-tools-plugins.dual-function-keys];
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.dual-function-keys}/bin/dual-function-keys -c ${dualFunctionFile} | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          NAME: "AT Translated Set 2 keyboard"
          EVENTS:
            EV_KEY: [KEY_MEDIA]
    '';
  };
}
