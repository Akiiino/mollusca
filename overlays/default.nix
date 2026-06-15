{ inputs }:
[
  (import ./gamescope.nix)
  (import ./swaylock-effects.nix)
  (import ./transmission_406.nix)
  (import ./yafc-ce.nix)
  (import ./XDG_fixes.nix)
  (import ./kakoune.nix { inherit inputs; })
]
