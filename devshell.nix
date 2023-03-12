{ nixpkgs, inputs }:
(nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
  let pkgs = nixpkgs.legacyPackages.${system};
  in {
    default = pkgs.mkShell {
      packages = with pkgs; [
        bash
        git
        nixfmt
        inputs.agenix.packages."${system}".default
      ];
    };
  }))
