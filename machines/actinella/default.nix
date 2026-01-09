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
    ./hardware-configuration.nix
    ./disko.nix
    ../nautilus/bigscreen.nix
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
    gui = {
      enable = true;
      desktopEnvironment = "plasma";
    };
    plymouth.enable = true;
    logitech.wireless.enable = true;
    eightbitdo.enable = true;
    bluetooth.enable = true;
    cec = {
      enable = true;
      connector = "card1-DP-2";
    };
  };

  services = {
    fwupd.enable = true;
  };

  programs = {
    crossmacro = {
        enable = true;
        users = ["actinella"];
    };
    steam.enable = true;
    nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 14d --keep 5";
      };
  };

  time.timeZone = "Europe/Berlin";

  networking = {
    hostName = "actinella";
  };

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    firefox
    keepassxc
    onboard
    vacuum-tube
    kitty
    jellyfin-media-player
  ];

  users.users = {
    actinella = {
      isNormalUser = true;
      password = "";
      extraGroups = [
        "audio"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile "${self}/secrets/keys/akiiino.pub")
        (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
      ];
    };
  };

  systemd.user.services.librespot = {
    description = "Librespot Spotify Connect";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" "pulseaudio.service" ];
    serviceConfig = {
      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.librespot}/bin/librespot"
        "--name 'actinella'"
        "--bitrate 320"
        "--backend pulseaudio"
        "--zeroconf-port 5354"
        "--device-type speaker"
        "--initial-volume 100"
      ];
      Restart = "always";
      RestartSec = 5;
    };
  };
  services = {
    displayManager.autoLogin.user = "actinella";
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
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
      mediaDir = "/var/lib/pinchflat/media";
      port = 8945;
      openFirewall = true;
      selfhosted = true;
    };
    jellyfin = {
        enable = true;
        openFirewall = true;
    };
  };
  boot.extraModprobeConfig = ''
    options snd_intel_dspcfg dsp_driver=3
  '';  # for audio through HDMI card
  networking.firewall = {
    allowedTCPPorts = [ 5354 ];
    allowedUDPPorts = [ 5353 ];
  };
}

