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
    { sdImage.compressImage = false; }
    self.inputs.nixos-hardware.nixosModules.raspberry-pi-4
    "${toString modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  config = {
    # # TODO: https://github.com/NixOS/nixpkgs/issues/154163
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
