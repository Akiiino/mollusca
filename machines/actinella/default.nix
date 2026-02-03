{
  self,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  kodiPackage = pkgs.kodi-gbm.withPackages (
    p: with p; [
      jellyfin
      # jellycon

      inputstream-adaptive
      inputstreamhelper

      invidious
    ]
  );
  librespotWithAvahi = pkgs.librespot.override {
    withAvahi = true;
    withMDNS = false;
  };
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ./disko.nix
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
    advertiseRoutes = "192.168.1.0/24";
    plymouth.enable = true;
    bluetooth.enable = true;
  };

  environment.systemPackages = with pkgs; [
    libcec
    kodiPackage
  ];

  users.users.actinella = {
    isNormalUser = true;
    password = "";
    extraGroups = [
      "audio"
      "video"
      "input" # kodi-gbm keyboard/remote input
      "render" # GPU acceleration
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
      (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
    ];
  };

  home-manager.users.actinella =
    { pkgs, ... }:
    {
      home.stateVersion = "25.11";

      programs.kodi = {
        enable = true;
        package = kodiPackage;

        settings = {
          services = {
            devicename = "actinella";

            webserver = "true";
            webserverport = "8080";
            webserverusername = "kodi";
            webserverpassword = "kodi";

            esallinterfaces = "true";
            esenabled = "true";
          };

          general = {
            addonupdates = "2";
            addonnotifications = "false";
          };

          videolibrary = {
            showemptytvshows = "true";
            cleanonupdate = "true";
          };

          locale = {
            timezonecountry = "Germany";
            timezone = "Europe/Berlin";
          };
        };
      };
    };

  systemd.user.services.librespot = {
    description = "Librespot Spotify Connect";
    wantedBy = [ "default.target" ];
    after = [
      "pipewire.service"
      "pulseaudio.service"
    ];
    serviceConfig = {
      ExecStart = builtins.concatStringsSep " " [
        "${librespotWithAvahi}/bin/librespot"
        "--name 'actinella'"
        "--bitrate 320"
        "--backend pulseaudio"
        "--zeroconf-port 5354"
        "--device-type speaker"
        "--initial-volume 100"
        "--zeroconf-backend avahi"
      ];
      Restart = "always";
      RestartSec = 5;
    };
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  age.secrets.actinella-backup.file = "${self}/secrets/actinella-backup.age";

  services = {
    fwupd.enable = true;

    greetd = {
      enable = true;
      settings.default_session = {
        command = lib.getExe' kodiPackage "kodi-standalone";
        user = "actinella";
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    pinchflat = {
      enable = true;
      mediaDir = "/mnt/media/YouTube/";
      port = 8945;
      openFirewall = true;
      selfhosted = true;
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    borgbackup.jobs.var-backup = {
      paths = [ "/var" ];
      repo = "/mnt/backups/actinella/var";

      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.age.secrets.actinella-backup.path}";
      };

      compression = "auto,zstd";

      prune.keep = {
        hourly = 24;
        daily = 7;
        weekly = -1;  # -1 means unlimited
      };

      startAt = "hourly";

      exclude = [
        "/var/cache"
        "/var/tmp"
        "/var/log/journal"
      ];

      extraCreateArgs = [
        "--stats"
        "--checkpoint-interval" "600"
      ];

      preHook = ''
        if ! ls /mnt/backups >/dev/null 2>&1; then
          echo "Backup destination not available"
          exit 1
        fi
      '';
    };
  };

  users.users.jellyfin = {
    extraGroups = [
      "render"
      "video"
    ];
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell and newer (ca. 2014+)
      intel-compute-runtime # OpenCL support
      libvdpau-va-gl # VDPAU via VA-API
      vpl-gpu-rt # something for Jellyfin
    ];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD"; # Jellyfin hardware transcoding

  boot.extraModprobeConfig = ''
    options snd_intel_dspcfg dsp_driver=3
    options i915 enable_guc=2
  ''; # for audio through HDMI card and GuC

  age.secrets.AmityTowerPassword.file = "${self}/secrets/AmityTower.age";
  networking = {
    hostName = "actinella";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        5354 # librespot
        8080 # Kodi web interface
        9090 # Kodi JSON-RPC
      ];
      allowedUDPPorts = [
        5353 # mDNS (Avahi)
        8080 # Kodi EventServer
      ];
    };
    networkmanager = {
      enable = true;
      ensureProfiles = {
        environmentFiles = [ config.age.secrets.AmityTowerPassword.path ];
        profiles = {
          home-wifi = {
            connection = {
              id = "Amity Tower";
              type = "wifi";
              autoconnect = true;
            };
            wifi = {
              ssid = "Amity Tower";
              mode = "infrastructure";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PASSWORD";
            };
            ipv4.method = "auto";
            ipv6.method = "auto";
          };
        };
      };
    };
  };

  boot.supportedFilesystems = [ "nfs" ];

  fileSystems."/mnt/media" = {
    device = "MyCloudEX2Ultra.local:/nfs/Media";
    fsType = "nfs";
    options = [
      "x-systemd.automount" # Mount on first access
      "noauto" # Don't mount at boot
      "x-systemd.idle-timeout=600" # Unmount after 10min idle
      "nfsvers=3"
      "hard" # hang if NAS is unavailable
      "timeo=50" # 5 second timeout
      "retrans=4" # 4 retries before giving up
      "_netdev" # Wait for network
    ];
  };
  fileSystems."/mnt/backups" = {
    device = "MyCloudEX2Ultra.local:/nfs/Backups";
    fsType = "nfs";
    options = [
      "x-systemd.automount" # Mount on first access
      "noauto" # Don't mount at boot
      "x-systemd.idle-timeout=600" # Unmount after 10min idle
      "nfsvers=3"
      "soft" # don't hang if NAS is unavailable
      "timeo=50" # 5 second timeout
      "retrans=4" # 4 retries before giving up
      "_netdev" # Wait for network
    ];
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  services.tlp = {
    enable = true;
    settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_BOOST_ON_AC = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 0;
      
      # CPU_MAX_PERF_ON_AC = 80;  # Limit to 80% of max frequency
      
      PLATFORM_PROFILE_ON_AC = "low-power";
      
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_CONTROLLER = "N";
      
      WIFI_PWR_ON_AC = "off";
    };
  };
  services.power-profiles-daemon.enable = false;
  services.thermald.enable = true;
}
