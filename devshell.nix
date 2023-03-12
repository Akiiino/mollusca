{ nixpkgs, inputs }:
(nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
  let pkgs = nixpkgs.legacyPackages.${system};
  in {
    default = pkgs.mkShell {
      packages = with pkgs; [
        bash
        git
        coreutils
        diffutils
        nixfmt
        sops
        inputs.ssh-to-age.packages."${system}".ssh-to-age
        inputs.agenix.packages."${system}".agenix
      ];
    };
  }))
