{
  config,
  pkgs,
  lib,
  self,
  nixos-hardware,
  modulesPath,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    self.inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    self.inputs.nixos-hardware.nixosModules.common-pc
    self.inputs.nixos-hardware.nixosModules.common-pc-ssd
    self.inputs.jovianNixOS.nixosModules.jovian
    "${self}/users/akiiino"
    "${self}/users/rinkaru"
  ];

  nix.settings.auto-optimise-store = true;
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      desktopSession = "plasma";
      user = "nautilus";
    };
    steamos.useSteamOSConfig = false;
  };

  mollusca.isRemote = true;
  mollusca.gui = {
    enable = true;
    desktopEnvironment = "plasma";
  };
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;


  # users.mutableUsers = false;
  users.users.nautilus = {
    isNormalUser = true;
    password = "";
    extraGroups = ["audio"];
    # uid = 1002;
    # group = "users";
  };
  # users.groups.users.gid = 100;

  networking = {
    hostName = "nautilus";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
        nvidia-vaapi-driver
      ];
    };

    nvidia = {
      modesetting.enable = true;
      open = false;

      nvidiaSettings = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
    bluetooth.enable = true;
  };

  # services.xserver = {
  #   enable = true;
  #   videoDrivers = ["nvidia"];
  #   displayManager.autoLogin.user = "nautilus";
  # };

  nixpkgs.config.pulseaudio = true;

  programs.zsh.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  environment.variables.DBUS_SYSTEM_BUS_ADDRESS = "steam";
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    firefox
  ];
}
