{
  self,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-11th-gen-intel
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ./disko.nix
    ./tv-filter.nix
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
    advertiseRoutes = "192.168.1.0/24";
    bluetooth.enable = true;
  };

  users.users.actinella = {
    isNormalUser = true;
    password = "";
    extraGroups = [
      "audio"
      "video"
      "render" # GPU acceleration
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
      (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
    ];
  };

  age.secrets.actinella-backup.file = "${self}/secrets/actinella-backup.age";

  services = {
    fwupd.enable = true;

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

    coredns = {
      enable = true;
      config = ''
        . {
          bind 127.0.0.1 192.168.1.101
          hosts ${self.inputs.stevenBlackHosts}/hosts {
            192.168.1.204 valetudo.akiiino.me
            192.168.1.101 akiiino.me
            fallthrough
          }
          # Cloudflare Forwarding
          forward . 1.1.1.1 1.0.0.1
          cache
        }
      '';
    };

    hostapd = {
      enable = true;
      radios.wlp170s0 = {
        band = "2g";
        channel = 11;
        wifi4.enable = true;

        networks.wlp170s0 = {
          ssid = "0ct0ptic0n";
          authentication = {
            mode = "wpa2-sha256";
            wpaPassword = "asynchronous rondo";  # or use wpaPasswordFile
          };
          # ignoreBroadcastSsid = "empty";
        };
      };
    };

    tvFilter = {
      enable = true;
      tvInterface  = "wlp170s0";
      wanInterface = "enp0s13f0u3u1";
      upstreamDNS = "127.0.0.1";
  
      allowedDomains = [
        # Spotify
        "spotify.com"
        "spotify.net"
        "spotifycdn.com"
        "scdn.co"
        "audio-ak-spotify-com.akamaized.net"
  
        # # YouTube
        # "youtube.com"
        # "googlevideo.com"
        # "ytimg.com"
        # "ggpht.com"
        # "googleapis.com"
        # "gstatic.com"
        # "google.com"
  
        # # Google Play
        # "play-lh.googleusercontent.com"
  
        # NTP
        "pool.ntp.org"
      ];
  
      allowedIPv4s = [
        # "8.8.8.8"
        # "8.8.4.4"
        "192.168.1.0/24"
      ];
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

  users.users.jellyfin.extraGroups = [
    "render"
    "video"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell and newer (ca. 2014+)
      intel-compute-runtime # OpenCL support
      libvdpau-va-gl # VDPAU via VA-API
      vpl-gpu-rt # something for Jellyfin
    ];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD"; # Jellyfin hardware transcoding
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD"; # Jellyfin hardware transcoding

  networking = {
    hostName = "actinella";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        53 # DNS
        80 # nginx
      ];
      allowedUDPPorts = [
        53 # DNS
        5353 # mDNS (Avahi)
      ];
    };
    # wireless.enable = false;
    # networkmanager.unmanaged = [ "wlan0" ];
  };

  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="DE"
  '';

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
