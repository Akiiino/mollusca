{ nixlib, ... }:
{
  takeLast = count: xs: nixlib.reverseList (nixlib.take count (nixlib.reverseList xs));

  removePrefixOrThrow =
    pref: str:
    (nixlib.throwIfNot (nixlib.hasPrefix pref str) "\"${str}\" does not start with \"${pref}\"") (
      nixlib.removePrefix pref str
    );
}
