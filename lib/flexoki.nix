# Flexoki — an inky color scheme for prose and code (https://stephango.com/flexoki).
#
# Single source of truth for the desktop colour palette. The full ramp (`base` +
# `accents`) is parsed from upstream's CSS custom properties
# (css/flexoki.css in the flexoki flake input) — Flexoki's public interface, so
# no hexes are transcribed here. Only the light-mode semantic UI aliases
# (`light`) are local: upstream encodes them solely in its TypeScript generator
# (_generators/src/palette.ts, not Nix-consumable), and the mapping below mirrors
# that file's lt_* names. Consumed as the `theme` module argument (wired in
# modules/base/all.nix). Per-app colour formatting (e.g. kakoune's `rgb:` prefix)
# lives in each consuming module, keeping this file pure data.
{ inputs, lib }:
let
  # Flatten `--flexoki-<name>: #RRGGBB;` declarations into { "<name>" = hex; },
  # where <name> is "paper", "black", a base step like "50", or "red-600".
  byName = builtins.listToAttrs (
    builtins.filter (x: x != null) (
      map (
        line:
        let
          m = builtins.match "[[:space:]]*--flexoki-([a-z0-9-]+):[[:space:]]*(#[0-9A-Fa-f]+);.*" line;
        in
        if m == null then null else lib.nameValuePair (builtins.head m) (builtins.elemAt m 1)
      ) (lib.splitString "\n" (builtins.readFile "${inputs.flexoki}/css/flexoki.css"))
    )
  );

  steps = [
    "50"
    "100"
    "150"
    "200"
    "300"
    "400"
    "500"
    "600"
    "700"
    "800"
    "850"
    "900"
    "950"
  ];

  # Reassemble the flat CSS map into the nested shape consumers expect:
  # base tones (paper .. black) and the eight accent ramps.
  base = {
    inherit (byName) paper black;
  }
  // lib.genAttrs steps (s: byName.${s});

  accents = lib.genAttrs [
    "red"
    "orange"
    "yellow"
    "green"
    "cyan"
    "blue"
    "purple"
    "magenta"
  ] (name: lib.genAttrs steps (s: byName."${name}-${s}"));

  accent = name: {
    base = accents.${name}."600";
    alt = accents.${name}."400";
  };

  # Light-mode semantic UI palette. This is what most consumers reference.
  # In light mode the UI shade is 600 and the brighter variant is 400.
  light = {
    bg = base.paper;
    bg2 = base."50";
    ui = base."100";
    ui2 = base."150";
    ui3 = base."200";
    tx3 = base."300";
    tx2 = base."600";
    tx = base.black;

    red = accent "red";
    orange = accent "orange";
    yellow = accent "yellow";
    green = accent "green";
    cyan = accent "cyan";
    blue = accent "blue";
    purple = accent "purple";
    magenta = accent "magenta";
  };
in
{
  inherit base accents light;
}
