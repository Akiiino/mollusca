{
  self,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    self.inputs.nixos-generators.nixosModules.all-formats
    self.inputs.mollusca-secrets.nixosModules.secrets
    self.inputs.agenix.nixosModules.default
    self.inputs.home-manager.nixosModules.default
    self.inputs.crossmacro.nixosModules.default
    self.inputs.disko.nixosModules.disko
    self.inputs.niri.nixosModules.niri

    "${self}/modules/mollusca"
  ];

  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
  };

  users.mutableUsers = false;
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = "all";
    extraLocaleSettings = {
      LC_NUMERIC = "en_IE.UTF-8";
      LC_TIME = "en_IE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_PAPER = "en_IE.UTF-8";
      LC_MEASUREMENT = "en_IE.UTF-8";
    };
  };
  system = {
    systemBuilderCommands = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
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
  nix.nixPath = [ "nixpkgs=/run/current-system/nixpkgs" ];
  services.openssh = {
    settings = {
      PasswordAuthentication = lib.mkForce false;
      PermitRootLogin = lib.mkForce "no";
    };
  };
}
