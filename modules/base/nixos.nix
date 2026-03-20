{
  self,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    self.inputs.agenix.nixosModules.default
    self.inputs.home-manager.nixosModules.default
    self.inputs.disko.nixosModules.disko
    self.inputs.niri.nixosModules.niri
    self.inputs.mini-agenix.nixosModules.mini-agenix

    "${self}/modules/mollusca"
  ];

  mini-agenix.enable = true;
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
    # extraLocales = "all";
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
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 14d --keep 5";
      };
    };
  };
  services.openssh = {
    settings = {
      PasswordAuthentication = lib.mkForce false;
      PermitRootLogin = lib.mkForce "no";
    };
  };
}
