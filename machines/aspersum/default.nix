{
  config,
  pkgs,
  lib,
  self,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
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
    extraGroups = [ "adbusers" ];
    hashedPassword = "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
  };
  nix.settings.auto-optimise-store = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    resumeDevice = "/dev/disk/by-uuid/b3688d3c-e0b0-4a29-9b99-14ae9d647bbb";
    kernelParams = [
      "amdgpu.sg_display=0"

      "resume_offset=533760"
      "rtc_cmos.use_acpi_alarm=1"

      # "quiet"
      # "splash"
      # "boot.shell_on_fail"
      # "udev.log_priority=3"
      # "rd.systemd.show_status=auto"

      "amd_pstate=active"
    ];

    # consoleLogLevel = 3;
    # initrd.verbose = false;
    # initrd.systemd.enable = true;

    # plymouth.enable = true;
  };

  # systemd.sleep.extraConfig = ''
  #   HibernateDelaySec=1h
  #   SuspendState=mem
  # '';

  powerManagement = {
    enable = true;
    powertop.enable = true;

    powerDownCommands = ''
      sync
    '';
  };

  networking = {
    hostName = "aspersum";
    networkmanager.enable = true;
    firewall = {
      allowedTCPPorts = [
        5000
        53317
        22000  # Syncthing
      ];
      allowedUDPPorts = [
        34197
        53317
        21027  # Syncthing
        22000  # Syncthing
      ];
    };
  };

  time.timeZone = "Europe/Berlin";

  mollusca = {
    gui = {
      enable = true;
      desktopEnvironment = "plasma";
    };
    isRemote = true;
    enableHM = true;
  };

  services = {
    power-profiles-daemon.enable = true;
    thermald.enable = true;
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    xserver.wacom.enable = true;
    fwupd.enable = true;
    fprintd.enable = true;

    beesd.filesystems."crypted" = {
      spec = "/dev/mapper/crypted";
      hashTableSizeMB = 512;
      extraOptions = [
        "--thread-count"
        "2"
      ];
    };
  };

  security.rtkit.enable = true;

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    gparted
    cheese
    usbutils
    btdu
    powertop
  ];

  programs = {
    steam.enable = true;
    zsh.enable = true;
    adb.enable = true;
  };

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
}
