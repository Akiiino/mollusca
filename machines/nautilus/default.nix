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
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    self.inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    self.inputs.nixos-hardware.nixosModules.common-pc
    self.inputs.nixos-hardware.nixosModules.common-pc-ssd
    "${self}/users/akiiino"
    "${self}/users/rinkaru"
  ];

  nix.settings.auto-optimise-store = true;
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  mollusca.isRemote = true;
  mollusca.gui = {
    enable = true;
    desktopEnvironment = "plasma";
  };
  users.users.nautilus = {
    isNormalUser = true;
    password = "";
    extraGroups = ["audio"];
  };

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

  services.xserver = {
    videoDrivers = ["nvidia"];
    displayManager.autoLogin.user = "nautilus";
  };

  nixpkgs.config.pulseaudio = true;

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
