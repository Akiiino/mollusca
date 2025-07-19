{self, ...}: let
  lib = self.inputs.nixpkgs.lib;
in {
  takeLast = count: xs:
    lib.reverseList (lib.take count (lib.reverseList xs));

  removePrefixOrThrow = pref: str:
    (lib.throwIfNot
      (lib.hasPrefix pref str)
      "\"${str}\" does not start with \"${pref}\"")
    (lib.removePrefix pref str);
}
