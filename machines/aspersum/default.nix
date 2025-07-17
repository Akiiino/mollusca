{
  config,
  pkgs,
  lib,
  self,
  ...
}: {
  # TODO:
  # configure Plasma to flip scroll and do suspend-then-hibernate
  imports = [
    self.inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ./hardware-configuration.nix
    ./disko.nix
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

  boot.resumeDevice = "/dev/disk/by-uuid/b3688d3c-e0b0-4a29-9b99-14ae9d647bbb";
  boot.kernelParams = [
    "amdgpu.sg_display=0"

    "resume_offset=533760"
    "rtc_cmos.use_acpi_alarm=1"
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  services.logind.suspendKey = "suspend-then-hibernate";
  services.logind.powerKey = "suspend-then-hibernate";
  services.logind.hibernateKey = "hibernate"; # Keep this as hibernate
  services.logind.lidSwitch = "suspend-then-hibernate";
  services.logind.lidSwitchExternalPower = "suspend-then-hibernate";
  services.logind.lidSwitchDocked = "suspend-then-hibernate";

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1h
    SuspendState=mem
  '';

  powerManagement = {
    enable = true;
    powertop.enable = true;

    powerDownCommands = ''
      sync
    '';
  };

  networking.hostName = "aspersum";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  mollusca.gui = {
    enable = true;
    desktopEnvironment = "plasma";
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

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    gparted
    cheese
    powertop
  ];

  programs = {
    steam.enable = true;
    zsh.enable = true;
    adb.enable = true;
  };
  networking.firewall.allowedTCPPorts = [5000 53317];
  networking.firewall.allowedUDPPorts = [34197 53317];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
  services.xserver.wacom.enable = true;
  services.fwupd.enable = true;
  services.fprintd.enable = true;

  services.beesd.filesystems."crypted" = {
    spec = "/dev/mapper/crypted";
    hashTableSizeMB = 512;
    extraOptions = ["--thread-count" "2"];
  };
}
