{self}: let
  lib = self.inputs.nixpkgs.lib;
in {
  takeLast = count: xs:
    lib.reverseList (lib.take count (lib.reverseList xs));
}
