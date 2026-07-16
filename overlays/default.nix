{ self, inputs }:
[
  (import ./gamescope.nix)
  (import ./flexoki-gtk.nix { inherit inputs; })
  (import ./swaylock-effects.nix)
  (import ./yafc-ce)
  (import ./XDG_fixes.nix)
  (import ./elephant.nix { inherit inputs; })
  (import ./walker.nix { inherit inputs; })
  (import ./kakoune.nix { inherit self inputs; })
  (import ./tremotesf)
]
