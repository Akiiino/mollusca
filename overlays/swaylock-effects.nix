# swaylock-effects' --effect-blur has an off-by-one error, making the blur
# "smear" towards a screen corner. This fixes it.

_: prev: {
  swaylock-effects = prev.swaylock-effects.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./swaylock-blur-centering.patch ];
  });
}

