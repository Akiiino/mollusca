{
  pkgs,
  self,
  inputs,
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
    "${self}/users/akiiino/desktop-niri.nix"
    "${self}/users/akiiino/personal.nix"
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Fix for the TTM LRU bulk-move list corruption that hard-freezes the
    # machine on GPU BO swap-in after (un)hibernation or under memory pressure.
    # Upstream: https://gitlab.freedesktop.org/drm/amd/-/issues/5387
    # Patch: "drm/ttm: Represent LRU bulk moves as nested sublists" [CI,v2]
    # https://patchwork.freedesktop.org/series/170311/ — adapted to v7.0.12
    # (one whitespace byte in a ttm_resource.c comment). Drop once the series
    # lands in a released kernel.
    kernelPatches = [
      {
        name = "ttm-lru-bulk-anchor-v2";
        patch = ./patches/ttm-lru-bulk-anchor-v2.patch;
      }
    ];

    binfmt.emulatedSystems = [ "aarch64-linux" ];

    resumeDevice = "/dev/disk/by-label/CRYPTED";
    kernelParams = [
      "resume_offset=533760" # sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile

      "rtc_cmos.use_acpi_alarm=1" # RTC wake alarm that fires to move suspend -> hibernate (suspend-then-hibernate).

      # These may or may not improve the chances of AMD's GPU unhibernating successfully.
      # 50% chance of successful unhibernation sure beats losing your data 100% of the time,
      # but it is very annoying. Don't buy AMD Ryzen AI 300.
      "amdgpu.cwsr_enable=0"
      "amdgpu.sg_display=0"
    ];

    initrd.systemd.enable = true; # TODO: is it reasonable to enable for all machines? Investigate.
    initrd.kernelModules = [ "amdgpu" ]; # helps plymouth start faster
  };

  powerManagement.enable = true;

  # Bound the s2idle window before suspend-then-hibernate drops to hibernate.
  # Idle-suspend on battery goes through `systemctl suspend-then-hibernate`
  # (see modules/desktop/niri/idle.sh); the RTC wake alarm above fires it.
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "lock";
  };

  networking = {
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

  mollusca.tailscaleRoutingFeatures = "client";

  services = {
    power-profiles-daemon.enable = true;
    resolved.enable = true;
    thermald.enable = true;
    upower.percentageCritical = 10;
    xserver.wacom.enable = true;

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

  security = {
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.NetworkManager.settings.modify.system" &&
            subject.user === "akiiino") {
          return polkit.Result.YES;
        }
      });
    ''; # allow ProtonVPN et al. to change settings without pestering
  };

  environment.localBinInPath = true;

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
