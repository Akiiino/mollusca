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
    };

    resumeDevice = "/dev/disk/by-label/CRYPTED";
    kernelParams = [
      "amdgpu.sg_display=0"
      "pcie_aspm=off"

      "resume_offset=533760"  # sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
      "rtc_cmos.use_acpi_alarm=1"

      "amd_pstate=active"
    ];

    initrd.systemd.enable = true;
  };

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
    plymouth.enable = true;
  };

  services = {
    power-profiles-daemon.enable = true;
    thermald.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.extraConfig.no-ucm = {  # FIXME: https://github.com/NixOS/nixos-hardware/issues/1603
        "monitor.alsa.properties" = {
          "alsa.use-ucm" = false;
        };
      };
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
  environment.systemPackages = [
    pkgs.cheese
    pkgs.usbutils
    pkgs.btdu
    pkgs.solaar
    pkgs.kdePackages.partitionmanager
    pkgs.kdePackages.skanlite
    (pkgs.kdePackages.skanpage.override {
      tesseractLanguages = [
        "eng"
        "deu"
        "rus"
      ];
    })
  ];

  programs = {
    steam.enable = true;
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
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };
  };
}
