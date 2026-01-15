{
  self,
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
  };

  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;
    grub.enable = true;
  };

  networking = {
    hostName = "pecten";
  };
}
