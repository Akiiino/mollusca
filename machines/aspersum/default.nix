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
      "amdgpu.dcdebugmask=0x410"  # remove if flicker persists
      "amdgpu.sg_display=0"
      "pcie_aspm=off"

      "resume_offset=533760"  # sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile

      "rtc_cmos.use_acpi_alarm=1"
    ];

    initrd.systemd.enable = true;
  };

  powerManagement.enable = true;

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
    logitech.wireless.enable = true;
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
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      # FIXME: https://github.com/NixOS/nixos-hardware/issues/1603
      wireplumber.extraConfig.no-ucm."monitor.alsa.properties"."alsa.use-ucm" = false;
    };
    xserver.wacom.enable = true;
    fwupd.enable = true;
    # libinput = {
    #   enable = true;
    #   touchpad = {
    #     disableWhileTyping = false;
    #     additionalOptions = ''
    #       Option "PalmDetect" "0"
    #     '';
    #   };
    # };

    beesd.filesystems."crypted" = {
      spec = "/dev/mapper/crypted";
      hashTableSizeMB = 512;
      extraOptions = [
        "--thread-count"
        "2"
      ];
    };
    opensnitch.enable = true;
  };
  home-manager.users.akiiino.services.opensnitch-ui.enable = true;

  security.rtkit.enable = true;

  environment.localBinInPath = true;
  environment.systemPackages = [
    pkgs.cheese
    pkgs.usbutils
    pkgs.btdu
    pkgs.kdePackages.partitionmanager
    pkgs.kdePackages.skanlite
    (pkgs.kdePackages.skanpage.override {
      tesseractLanguages = [
        "eng"
        "deu"
        "rus"
      ];
    })
    (pkgs.tic-80.override {withPro = true;})
  ];

  programs = {
    steam.enable = true;
    adb.enable = true;
    nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 14d --keep 5";
      };
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
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };
  };
}
