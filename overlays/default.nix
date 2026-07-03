{ inputs }:
[
  (import ./gamescope.nix)
  (import ./swaylock-effects.nix)
  (import ./yafc-ce)
  (import ./XDG_fixes.nix)
  (import ./elephant.nix { inherit inputs; })
  (import ./walker.nix { inherit inputs; })
  (import ./kakoune.nix { inherit inputs; })
]
