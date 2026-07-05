{ inputs }:
final: prev: {
  mollusca = (prev.mollusca or { }) // {
    kakoune = import ../modules/apps/kakoune/package.nix {
      pkgs = final;
      inherit inputs;
      inherit (final) lib;
      theme = import ../lib/flexoki.nix {
        inherit inputs;
        inherit (final) lib;
      };
    };
  };
}
