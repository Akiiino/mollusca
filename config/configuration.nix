# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }: {
  imports = [ ./hardware-configuration.nix ];
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "spotify"
      "spotify-unwrapped"
      "discord"
      "steam"
      "steam-original"
      "steam-runtime"
      "steam-run"
      "obsidian"
      "slack"
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "akiiinixos"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.defaultSession = "gnome";
    desktopManager = {
      xterm.enable = false;
      xfce.enable = false;
      gnome.enable = true;
    };
  };

  services.printing.enable = true; # printing
  # services.fprintd.enable = true;  # fingerprints

  # Enable sound.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.gnome.core-utilities.enable = false;
  environment.systemPackages = with pkgs; [
    gparted
    gnome.eog
    gnome.evince
    gnome.nautilus
    gnome.totem
    gnome.gnome-bluetooth
    gnome.gnome-calculator
    gnome.gnome-screenshot
    # gnome.simple-scan
    # gnome-user-docs
    gnome.file-roller
    gnome.gnome-clocks
    gnome.gnome-music
    gnome.gnome-tweaks
    gnome-photos
    gnome.gnome-calendar
    gnome.gnome-power-manager
    gnome.gedit
    gnome.cheese
    gnome.dconf-editor
    gnome.gnome-remote-desktop
  ];
  environment.gnome.excludePackages = with pkgs; [ gnome-tour ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;

  programs.adb.enable = true;

  networking.firewall.allowedTCPPorts = [ 3389 5900 5000 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}

