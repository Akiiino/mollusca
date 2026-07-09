{
  self,
  lib,
  ...
}:
{
  imports = [
    self.inputs.agenix.nixosModules.default
    self.inputs.home-manager.nixosModules.default
    self.inputs.disko.nixosModules.disko
    self.inputs.niri.nixosModules.niri
    self.inputs.horai.nixosModules.eunomia

    "${self}/modules"
    ./nix.nix
    ./home-manager.nix
    ./remote.nix
  ];

  niri-flake.cache.enable = false;
  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };

  documentation.nixos.enable = false;

  users.mutableUsers = false;
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_NUMERIC = "en_IE.UTF-8";
      LC_TIME = "en_IE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_PAPER = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
    };
  };

  system = {
    stateVersion = "23.11";
  };

  programs = {
    nix-ld.enable = true;
    zsh.enable = true;
  };

  time.timeZone = lib.mkDefault "Europe/Berlin";
}
