{ inputs }:
[
  (import ./gamescope.nix)
  (import ./swaylock-effects.nix)
  (import ./yafc-ce)
  (import ./XDG_fixes.nix)
  (import ./elephant.nix)
  (import ./kakoune.nix { inherit inputs; })
]
