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
