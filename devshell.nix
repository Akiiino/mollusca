{
  self,
  nixpkgs,
  inputs,
}: (nixpkgs.lib.genAttrs ["x86_64-linux"] (system: let
  pkgs = nixpkgs.legacyPackages.${system};
in {
  default = pkgs.mkShell {
    packages = with pkgs; [
      bash
      git
      coreutils
      moreutils
      diffutils
      nixfmt
      sops
      inputs.ssh-to-age.packages."${system}".ssh-to-age
      inputs.agenix.packages."${system}".agenix
      (writeShellScriptBin "encrypt" (builtins.readFile "${self}/scripts/encrypt.sh"))
      (writeShellScriptBin "decrypt" (builtins.readFile "${self}/scripts/decrypt.sh"))
    ];
  };
}))
