# The package recipe lives with its HM module (modules/home/kakoune/) next to
# the rc/ files it bundles. `theme` is re-imported here because overlays
# evaluate outside the module system, where the specialArg doesn't exist.
{ self, inputs }:
final: prev: {
  mollusca = (prev.mollusca or { }) // {
    kakoune = import "${self}/modules/home/kakoune/package.nix" {
      pkgs = final;
      inherit inputs;
      inherit (final) lib;
      theme = import "${self}/modules/desktop/theming/flexoki.nix" {
        inherit inputs;
        inherit (final) lib;
      };
    };
  };
}
