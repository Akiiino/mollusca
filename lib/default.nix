{
  inputs,
  self,
}: let
  lib = inputs.nixpkgs.lib;
  machines = import ./machines.nix {inherit self;};
  utils = import ./utils.nix {inherit self;};
  networking = import ./networking.nix {inherit self;};
in {
  inherit (machines) mkNixOSMachine mkNixOSMachines mkDarwinMachine;
  inherit (utils) takeLast removePrefixOrThrow;
  inherit (networking) mkProxy mkVirtualHost mkCifs;
}
