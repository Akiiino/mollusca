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
    kernelPackages = pkgs.linuxPackages_6_6;
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };

    resumeDevice = "/dev/disk/by-uuid/b3688d3c-e0b0-4a29-9b99-14ae9d647bbb";
    kernelParams = [
      "amdgpu.sg_display=0"
      "pcie_aspm=off"

      "resume_offset=533760"
      "rtc_cmos.use_acpi_alarm=1"

      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"

      "amd_pstate=active"
    ];

    consoleLogLevel = 3;
    initrd.verbose = false;
    initrd.systemd.enable = true;

    plymouth.enable = true;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="27c6", ATTRS{idProduct}=="*", TEST=="power/persist", ATTR{power/persist}="1"
  '';

  powerManagement = {
    enable = true;

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
        22000 # Syncthing
      ];
      allowedUDPPorts = [
        34197
        53317
        21027 # Syncthing
        22000 # Syncthing
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

    beesd.filesystems."crypted" = {
      spec = "/dev/mapper/crypted";
      hashTableSizeMB = 512;
      extraOptions = [
        "--thread-count"
        "2"
      ];
    };
  };

  systemd.user.services.solaar = {
    description = "Solaar, the open source driver for Logitech devices";
    wantedBy = [ "graphical-session.target" ];
    after = [ "dbus.service" ];
    environment = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe' pkgs.solaar "solaar"} --window hide";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };
  security.rtkit.enable = true;

  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [
    cheese
    usbutils
    btdu
    solaar
    kdePackages.partitionmanager
  ];

  programs = {
    steam.enable = true;
    zsh.enable = true;
    adb.enable = true;
  };

  hardware = {
    framework.laptop13.audioEnhancement = {
      enable = true;
      hideRawDevice = false;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
    logitech.wireless = {
      enable = true;
      enableGraphical = lib.mkForce false;
    };
  };
}
