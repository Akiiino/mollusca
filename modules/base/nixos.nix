{
  self,
  pkgs,
  lib,
  config,
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

  systemd.services.gc-generations = {
    description = "Delete old NixOS generations, keeping the last 5";
    serviceConfig.Type = "oneshot";
    path = [ config.nix.package ];
    script = ''
      nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
      nix-collect-garbage
    '';
  };

  systemd.timers.gc-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  programs = {
    nix-ld.enable = true;
  };
  services.openssh = {
    settings = {
      PasswordAuthentication = lib.mkForce false;
      PermitRootLogin = lib.mkForce "no";
    };
  };
}
