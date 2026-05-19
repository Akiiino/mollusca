# Pins Transmission 4.0.6 as `transmission_4`, fetched from the nixpkgs
# revision right before the 4.1.0-beta upgrade.
#
# Why an overlay (not overrideAttrs): the derivation changed between
# 4.0.6 and 4.1.0 (new deps, build flags), so just swapping `src` and
# `version` on the current `transmission_4` won't build.
#
# Why fetch one file (not a whole nixpkgs input): keeps eval cheap and
# avoids carrying around a second nixpkgs just to obtain one package.
#
# Caveat: this re-uses *current* nixpkgs for all of 4.0.6's
# dependencies (libb64, utf8cpp, fast-float, fmt, …). If any of those
# get removed or renamed in nixpkgs in the future, this overlay will
# fail to evaluate — at which point either vendor the file locally or
# bump to a newer pin.

_final: prev: {
  transmission_4 = prev.callPackage (builtins.fetchurl {
    url = "https://raw.githubusercontent.com/NixOS/nixpkgs/48b3a1cabf2a92a4ae6f254ee0c726c0226768d5/pkgs/applications/networking/p2p/transmission/4.nix";
    sha256 = "5c9da7584ad50242ea2619f32deed9eeb166472e1c25026b78e7bffe7ac40f54";
  }) { };
}
