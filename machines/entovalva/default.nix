{
  self,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${self}/modules/raspberrypi.nix"
    ./tv-filter.nix
  ];

  services.resolved.enable = true;

  services.tvFilter = {
    enable = true;
    tvInterface  = "end0";
    wanInterface = "wlan0";

    allowedDomains = [
      # Spotify
      "spotify.com"
      "spotify.net"
      "spotifycdn.com"
      "scdn.co"
      "audio-ak-spotify-com.akamaized.net"

      # YouTube
      "youtube.com"
      "googlevideo.com"
      "ytimg.com"
      "ggpht.com"
      "googleapis.com"
      "gstatic.com"
      "google.com"

      # Google Play
      "play-lh.googleusercontent.com"

      # NTP
      "pool.ntp.org"
    ];

    allowedIPv4s = [
      # "8.8.8.8"
      # "8.8.4.4"
      "192.168.1.0/24"
    ];
  };

  mollusca = {
    isRemote = true;
  };

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  age.secrets.AmityTowerPassword.file = "${self}/secrets/AmityTower.age";

  networking = {
    hostName = "entovalva";
    domain = "";
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
}
