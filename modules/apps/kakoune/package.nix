{
  pkgs,
  inputs,
  lib,
  theme,
}:
let
  kakoune-unwrapped = pkgs.kakoune-unwrapped.overrideAttrs (old: {
    version = "2026.05.21";
    src = inputs.kakoune;
  });

  plugins = [
    pkgs.kakounePlugins.kak-ansi
    pkgs.kakounePlugins.powerline-kak
    pkgs.kakounePlugins.openscad-kak
    pkgs.kakounePlugins.kakoune-buffers
    (inputs.parinfer-rust.packages.${pkgs.stdenv.hostPlatform.system}.parinfer-rust.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ./parinfer.patch ];
      })
    )
    inputs.kak-yac.packages.${pkgs.stdenv.hostPlatform.system}.kak-yac
  ];

  kakoune-with-plugins = pkgs.wrapKakoune kakoune-unwrapped { inherit plugins; };

  # Flexoki palette exposed to kakoune as `flx_*` string options, derived from
  # the shared attrset (lib/flexoki.nix). The static rc/ files reference these
  # via %opt{flx_*}, so this generated file is the only place colours enter.
  l = theme.light;
  # kakoune wants colours as `rgb:rrggbb` (no leading '#').
  kak = c: "rgb:" + lib.toLower (lib.removePrefix "#" c);
  paletteOptions = {
    flx_bg = l.bg;
    flx_bg2 = l.bg2;
    flx_ui = l.ui;
    flx_ui2 = l.ui2;
    flx_ui3 = l.ui3;
    flx_tx3 = l.tx3;
    flx_tx2 = l.tx2;
    flx_tx = l.tx;
    flx_red = l.red.base;
    flx_red2 = l.red.alt;
    flx_orange = l.orange.base;
    flx_orange2 = l.orange.alt;
    flx_yellow = l.yellow.base;
    flx_yellow2 = l.yellow.alt;
    flx_green = l.green.base;
    flx_green2 = l.green.alt;
    flx_cyan = l.cyan.base;
    flx_cyan2 = l.cyan.alt;
    flx_blue = l.blue.base;
    flx_blue2 = l.blue.alt;
    flx_purple = l.purple.base;
    flx_purple2 = l.purple.alt;
    flx_magenta = l.magenta.base;
    flx_magenta2 = l.magenta.alt;
  };
  paletteKak = pkgs.writeText "flexoki-palette.kak" (
    "# Generated from lib/flexoki.nix — do not edit by hand.\n"
    + lib.concatStrings (
      lib.mapAttrsToList (n: v: ''declare-option -hidden str ${n} "${kak v}"'' + "\n") paletteOptions
    )
  );

  configDir = pkgs.runCommandLocal "kakoune-config" { } ''
    mkdir -p "$out"
    cp -r ${./rc}/. "$out"/
    cp ${paletteKak} "$out"/flexoki-palette.kak
  '';
in
inputs.wrapper-manager.lib.wrapWith pkgs {
  basePackage = kakoune-with-plugins;
  pathAdd = [
    pkgs.proselint
    pkgs.wl-clipboard
    (pkgs.kakoune-lsp.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./kakoune-lsp.patch ];
    }))
    pkgs.nixd
    pkgs.nixfmt
    pkgs.basedpyright
    pkgs.ruff
    inputs.janet-lsp.packages.${pkgs.stdenv.hostPlatform.system}.janet-lsp
    pkgs.ripgrep
  ];
  env.KAKOUNE_CONFIG_DIR.value = configDir;
}
