params @ {
  inputs,
  self,
  ...
}: let
  lib = inputs.nixpkgs.lib;
  machines = import ./machines.nix params;
  utils = import ./utils.nix params;
  networking = import ./networking.nix params;
in {
  inherit (machines) mkNixOSMachine mkNixOSMachines mkDarwinMachine mkDarwinMachines;
  inherit (utils) takeLast removePrefixOrThrow;
  inherit (networking) mkProxy mkVirtualHost mkCifs;
}
