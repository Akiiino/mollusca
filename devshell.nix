{
  self,
  pkgs,
  inputs,
}:
pkgs.mkShell {
  name = "seashell";
  packages = with pkgs; [
    bash
    git
    coreutils
    moreutils
    diffutils
    sops
    inputs.ssh-to-age.packages."${system}".ssh-to-age
    inputs.agenix.packages."${system}".agenix
    (writeShellScriptBin "encrypt" (builtins.readFile "${self}/scripts/encrypt.sh"))
    (writeShellScriptBin "decrypt" (builtins.readFile "${self}/scripts/decrypt.sh"))
    (writeShellScriptBin "rebuild" (builtins.readFile "${self}/scripts/rebuild.sh"))
  ];
}
