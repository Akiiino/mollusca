{
  config,
  pkgs,
  lib,
  self,
  nixos-hardware,
  modulesPath,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    self.inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    self.inputs.nixos-hardware.nixosModules.common-pc
    self.inputs.nixos-hardware.nixosModules.common-pc-ssd
    "${self}/users/akiiino"
    "${self}/users/rinkaru"
    ./bigscreen.nix
    self.inputs.crossmacro.nixosModules.default
  ];

  nix.settings.auto-optimise-store = true;

  boot = {
    kernelParams = [ "amd_pstate=active" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelPackages = pkgs.linuxPackages_latest;
  };

  powerManagement.cpuFreqGovernor = "performance";

  mollusca = {
    isRemote = true;
    gui = {
      enable = true;
      desktopEnvironment = "plasma";
    };
    plymouth.enable = true;
    logitech.wireless.enable = true;
    eightbitdo.enable = true;
  };

  # users.mutableUsers = false;
  users.users = {
    nautilus = {
      isNormalUser = true;
      password = "";
      extraGroups = [
        "audio"
        "input"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile "${self}/secrets/keys/akiiino.pub")
        (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
      ];
    };
    akiiino = {
      isNormalUser = true;
      password = "";
      extraGroups = [
        "audio"
        "input"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile "${self}/secrets/keys/akiiino.pub")
      ];
    };
  };
  # users.groups.users.gid = 100;

  networking = {
    hostName = "nautilus";
    networkmanager.enable = true;

    firewall = {
      allowedTCPPorts = [ 11111 ];
      allowedUDPPorts = [ 11111 ];
    };
  };

  time.timeZone = "Europe/Berlin";

  hardware = {
    graphics = {
      enable = true;
      # driSupport = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    nvidia = {
      modesetting.enable = true;
      open = true;

      nvidiaSettings = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
    pulseaudio = {
      enable = false;
      support32Bit = true;
    };
    displayManager.autoLogin.user = "nautilus";
  };

  programs = {
    crossmacro = {
        enable = true;
        addUsersToInputGroup = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    firefox
    keepassxc
    onboard
  ];
}
