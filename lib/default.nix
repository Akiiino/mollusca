params:
let
  machines = import ./machines.nix params;
in
{
  inherit (machines) mkNixOSMachines mkDarwinMachines;
}
