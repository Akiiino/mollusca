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
    inputs.agenix.packages."${system}".agenix
    (writeShellScriptBin "rebuild" (builtins.readFile "${self}/scripts/rebuild.sh"))
    (writeShellScriptBin "recreate" (builtins.readFile "${self}/scripts/recreate.sh"))
  ];
}
