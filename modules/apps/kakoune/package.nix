{
  pkgs,
  inputs,
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
    (inputs.parinfer-rust.packages.${pkgs.stdenv.hostPlatform.system}.parinfer-rust.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ./parinfer.patch ];
      })
    )
    inputs.kak-yac.packages.${pkgs.stdenv.hostPlatform.system}.kak-yac
  ];

  kakoune-with-plugins = pkgs.wrapKakoune kakoune-unwrapped { inherit plugins; };
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
  ];
  env.KAKOUNE_CONFIG_DIR.value = ./rc;
}
