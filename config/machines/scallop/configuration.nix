{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect

  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "scallop";
  networking.domain = "";
  services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
  };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "22.05";

  environment.systemPackages = with pkgs; [ kakoune ];
}
