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
    # TODO: remove if the breakage is fixed
    nixpkgs.overlays = [
      (final: super: {
        makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];
    services.hardware.argonone.enable = true;
  };
}
