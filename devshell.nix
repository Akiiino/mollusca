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
    nix-prefetch-scripts
    inputs.agenix.packages."${system}".agenix
    inputs.gitsh.packages."${system}".gitsh
    inputs.nh.packages."${system}".nh
  ];
}
