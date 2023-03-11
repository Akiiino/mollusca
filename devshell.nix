{ nixpkgs, inputs }:
(nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system:
  let pkgs = nixpkgs.legacyPackages.${system};
  in {
    default = pkgs.mkShell {
      packages = with pkgs; [
        bash
        git
        agebox
        nixfmt
        inputs.agenix.packages."${system}".default
        (writeShellScriptBin "encrypt" ''
          exec agebox encrypt --all
        '')
        (writeShellScriptBin "decrypt" ''
          exec agebox decrypt --all
        '')
      ];
      AGEBOX_PUBLIC_KEYS = "secrets/keys";
    };
  }))
