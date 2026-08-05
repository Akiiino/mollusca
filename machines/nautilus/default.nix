{
  config,
  pkgs,
  self,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    "${self}/profiles/desktop-plasma.nix"
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    self.inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    self.inputs.nixos-hardware.nixosModules.common-pc
    self.inputs.nixos-hardware.nixosModules.common-pc-ssd
    "${self}/users/akiiino/base.nix"
    "${self}/users/akiiino/desktop.nix"
    "${self}/users/rinkaru"
  ];

  boot = {
    kernelParams = [ "amd_pstate=active" ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelPackages = pkgs.linuxPackages_6_12;
  };

  powerManagement.cpuFreqGovernor = "performance";

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
    akiiino.extraGroups = [
      "audio"
      "input"
    ];
  };

  networking = {
    firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  hardware = {
    graphics = {
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
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
    pulseaudio.enable = false;
    displayManager.autoLogin.user = "nautilus";
  };

  programs = {
    steam = {
      remotePlay.openFirewall = true;
      # gamescopeSession = {
      #   enable = true;
      # };
    };
    # gamescope = {
    #   enable = true;
    #   capSysNice = true;
    # };
  };

  # services.displayManager.defaultSession = "steam";

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    firefox
    keepassxc
    onboard
  ];
}
