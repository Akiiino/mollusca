params:
let
  machines = import ./machines.nix params;
  utils = import ./utils.nix params;
  networking = import ./networking.nix params;
in
{
  inherit (machines) mkNixOSMachines mkDarwinMachines;
}
