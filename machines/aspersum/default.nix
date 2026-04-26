{
  pkgs,
  self,
  self',
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ./hardware-configuration.nix
    ./disko.nix
    "${self}/users/akiiino"
    "${self}/users/akiiino/home-manager.nix"
  ];

  # documentation.nixos = {
  #   enable = true;
  #   options.warningsAreErrors = false;
  #   includeAllModules = true;
  # };

  users.users.akiiino = {
    extraGroups = [ "adbusers" ];
    hashedPassword = "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    resumeDevice = "/dev/disk/by-label/CRYPTED";
    kernelParams = [
      "resume_offset=533760" # sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile

      "rtc_cmos.use_acpi_alarm=1" # TODO: why is this here? Figure out if this fix is sill needed.
    ];

    initrd.systemd.enable = true; # TODO: is it reasonable to enable for all machines? Investigate.
  };

  powerManagement.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  networking = {
    hostName = "aspersum";
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

  mollusca = {
    gui = {
      enable = true;
      desktopEnvironment = "niri";
    };
    isRemote = true;
    logitech.wireless.enable = true;
    eightbitdo.enable = true;
    bluetooth.enable = true;
    useTailscale = true;
    tailscaleRoutingFeatures = "client";
  };

  services = {
    resolved.enable = true;
    power-profiles-daemon.enable = true;
    thermald.enable = true;
    upower.percentageCritical = 10;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    printing = {
      enable = true;
      drivers = [ self'.packages.cups-brother-dcpl3520cdw ];
    };
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
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", KERNEL=="0000:c3:00.0", ATTR{power/control}="on"
    ''; # fixes the annoying "xhci_hcd 0000:c3:00.0: Refused to change power state from D0 to D3hot"
    tailscale = {
      extraSetFlags = [ "--operator=akiiino" ];
    };
    displayManager.autoLogin.user = "akiiino";
  };

  security.rtkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id === "org.freedesktop.NetworkManager.settings.modify.system" &&
          subject.user === "akiiino") {
        return polkit.Result.YES;
      }
    });
  ''; # allow ProtonVPN et al. to change settings without pestering

  environment.localBinInPath = true;
  environment.systemPackages = [
    pkgs.trayscale
    pkgs.cheese
    pkgs.usbutils
    pkgs.btdu
    pkgs.kdePackages.partitionmanager
    pkgs.kdePackages.skanlite
    pkgs.evince
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
    # framework.laptop13.audioEnhancement = { # doesn't do anything :( # TODO: figure out why?
    #   enable = true;
    #   hideRawDevice = false;
    # };
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };
  };

  mollusca.nasMounts."/mnt/media".share = "MyCloudEX2Ultra.local:/nfs/Media";
}
