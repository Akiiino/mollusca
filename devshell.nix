{
  pkgs,
  inputs',
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
    inputs'.agenix.packages.agenix
    inputs'.gitsh.packages.gitsh
    nh
  ];
}
