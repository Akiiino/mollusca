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
    "${self}/users/akiiino"
    "${self}/users/rinkaru"
  ];

  nix.settings.auto-optimise-store = true;
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  mollusca.isRemote = true;
  mollusca.gui = {
    enable = true;
    desktopEnvironment = "plasma";
  };

  # users.mutableUsers = false;
  users.users.nautilus = {
    isNormalUser = true;
    password = "";
    extraGroups = ["audio"];
    # uid = 1002;
    # group = "users";
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
      (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
    ];
  };
  users.users.akiiino = {
    isNormalUser = true;
    password = "";
    extraGroups = ["audio"];
    # uid = 1002;
    # group = "users";
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
      (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
    ];
  };
  # users.groups.users.gid = 100;

  networking = {
    hostName = "nautilus";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  hardware = {
    graphics = {
      enable = true;
      # driSupport = true;
      enable32Bit = true;
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
      powerManagement.enable = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["nvidia"];
  };
  services.pulseaudio = {
    enable = false;
    support32Bit = true;
  };
  # services.displayManager.autoLogin.user = "nautilus";

  nixpkgs.config.pulseaudio = true;

  networking.firewall.allowedTCPPorts = [11111];
  networking.firewall.allowedUDPPorts = [11111];

  programs.zsh.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };
  # environment.variables.DBUS_SYSTEM_BUS_ADDRESS = "steam";
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    firefox
    keepassxc
    onboard
  ];
}
