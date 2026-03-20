{
  self,
  config,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    "${modulesPath}/profiles/perlless.nix"
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    isExitNode = true;
  };

  # TODO: move to `mollusca.remote` or `mollusca.headless`?
  system.tools = {
    nixos-rebuild.enable = false;
    nixos-install.enable = false;
    nixos-generate-config.enable = false;
    nixos-enter.enable = false;
    nixos-build-vms.enable = false;
    nixos-option.enable = false;
  };

  xdg.mime.enable = false;  # not needed on a headless server

  # To resolve nixpkgs (e.g. nix run nixpkgs#hello) lazily,
  # instead of building it into the closure (saves ~300 MB):

  nixpkgs.flake.source = lib.mkForce null;
  nix = {
    registry.nixpkgs = {
      from = { type = "indirect"; id = "nixpkgs"; };
      to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        rev = inputs.nixpkgs.rev;
      };
    };
    settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
  };


  networking = {
    hostName = "pecten";
  };
}
