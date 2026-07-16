{
  lib,
  inputs,
  ...
}:
{
  mollusca = {
    isRemote = true;
    useTailscale = true;
  };

  system.tools = {
    nixos-rebuild.enable = false;
    nixos-install.enable = false;
    nixos-generate-config.enable = false;
    nixos-enter.enable = false;
    nixos-build-vms.enable = false;
    nixos-option.enable = false;
  };

  xdg.mime.enable = false;

  # To resolve nixpkgs (e.g. nix run nixpkgs#hello) lazily,
  # instead of building it into the closure (saves ~300 MB):

  nixpkgs.flake.source = lib.mkForce null;
  nix = {
    registry.nixpkgs = {
      from = {
        type = "indirect";
        id = "nixpkgs";
      };
      to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (inputs.nixpkgs) rev;
      };
    };
    settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
  };
}
