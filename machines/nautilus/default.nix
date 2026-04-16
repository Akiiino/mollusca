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
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    self.inputs.nixos-hardware.nixosModules.common-cpu-amd-raphael-igpu
    self.inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    self.inputs.nixos-hardware.nixosModules.common-pc
    self.inputs.nixos-hardware.nixosModules.common-pc-ssd
    "${self}/users/akiiino"
    "${self}/users/rinkaru"
  ];

  boot = {
    kernelParams = [ "amd_pstate=active" ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelPackages = pkgs.linuxPackages_6_12;
  };

  powerManagement.cpuFreqGovernor = "performance";

  mollusca = {
    isRemote = true;
    gui = {
      enable = true;
      desktopEnvironment = "plasma";
    };
    logitech.wireless.enable = true;
    eightbitdo.enable = true;
    bluetooth.enable = true;
  };

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
    akiiino = { # intentionally modified from users/akiiino
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

  networking = {
    hostName = "nautilus";
    firewall = {
      allowedTCPPorts = [ 11111 ]; # TODO: what are the ports for?
      allowedUDPPorts = [ 11111 ];
    };
  };

  hardware = {
    graphics = {
      enable = true;
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
      #package = config.boot.kernelPackages.nvidiaPackages.stable;
      # TODO: remove after https://github.com/ValveSoftware/gamescope/issues/1964 is fixed
      # or >580 is available
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "575.64.05";
        sha256_64bit = "sha256-hfK1D5EiYcGRegss9+H5dDr/0Aj9wPIJ9NVWP3dNUC0=";
        sha256_aarch64 = "sha256-GRE9VEEosbY7TL4HPFoyo0Ac5jgBHsZg9sBKJ4BLhsA=";
        openSha256 = "sha256-mcbMVEyRxNyRrohgwWNylu45vIqF+flKHnmt47R//KU=";
        settingsSha256 = "sha256-o2zUnYFUQjHOcCrB0w/4L6xI1hVUXLAWgG2Y26BowBE=";
        persistencedSha256 = "sha256-2g5z7Pu8u2EiAh5givP5Q1Y4zk4Cbb06W37rf768NFU=";
      };
    };
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
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      gamescopeSession = {
        enable = true;
      };
    };
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  services.displayManager.defaultSession = "steam";

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    firefox
    keepassxc
    onboard
  ];
}
