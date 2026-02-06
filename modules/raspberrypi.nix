{
  self,
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  # TODO: If ever it becomes possible to make this conditional, add an `enable` option
  imports = [
    self.inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];
  config = {
    # # TODO: https://github.com/NixOS/nixpkgs/issues/154163
    image.modules.sd-card.sdImage.compressImage = false;
    nixpkgs.overlays = [
      (final: super: {
        makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];
    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    services.hardware.argonone.enable = true;
    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = false;
    };
  };
}
