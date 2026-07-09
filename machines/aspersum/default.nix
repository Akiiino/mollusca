{
  pkgs,
  self,
  self',
  inputs,
  config,
  ...
}:
{
  imports = [
    "${self}/profiles/desktop-niri.nix"
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ./hardware-configuration.nix
    ./disko.nix
    "${self}/users/akiiino/base.nix"
    "${self}/users/akiiino/desktop.nix"
    "${self}/users/akiiino/personal.nix"
  ];

  age.secrets.akiiino-password.file = "${self}/secrets/akiiino-password.age";
  users.users.akiiino.hashedPasswordFile = config.age.secrets.akiiino-password.path;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    resumeDevice = "/dev/disk/by-label/CRYPTED";
    kernelParams = [
      "resume_offset=533760" # sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile

      "rtc_cmos.use_acpi_alarm=1" # RTC wake alarm that fires to move suspend -> hibernate (suspend-then-hibernate).

      "amdgpu.cwsr_enable=0" # possibly helps with unhibernation; if doesn't, add next line
      "amdgpu.sg_display=0" # eeh... Maybe will also help? I hate AMD.
    ];

    initrd.systemd.enable = true; # TODO: is it reasonable to enable for all machines? Investigate.
    initrd.kernelModules = [ "amdgpu" ]; # helps plymouth start faster
  };

  powerManagement.enable = true;

  # Bound the s2idle window before suspend-then-hibernate drops to hibernate.
  # Idle-suspend on battery goes through `systemctl suspend-then-hibernate`
  # (see modules/apps/desktop-shell/idle.sh); the RTC wake alarm above fires it.
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  networking = {
    hostName = "aspersum";
    firewall = {
      allowedTCPPorts = [
        53317 # Localsend
        22000 # Syncthing
      ];
      allowedUDPPorts = [
        34196 # Factorio LAN discovery
        34197 # Factorio
        53317 # Localsend
        21027 # Syncthing
        22000 # Syncthing
      ];
    };
  };

  mollusca = {
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
    tailscale.extraSetFlags = [ "--operator=akiiino" ];
    displayManager.autoLogin.user = "akiiino";

    # yubikey
    pcscd.enable = true;
    udev.packages = [
      pkgs.yubikey-personalization
      pkgs.ccid
    ];
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

  programs = {
    steam.enable = true;
  };

  hardware = {
    framework.laptop13.audioEnhancement = {
      enable = true;
      hideRawDevice = false;
      rawDeviceName = "alsa_output.pci-0000_c1_00.6.analog-stereo";
    };
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };
  };

  mollusca.nasMounts."/mnt/media".share = "MyCloudEX2Ultra.local:/nfs/Media";
}
