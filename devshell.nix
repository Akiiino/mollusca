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
    inputs'.mini-agenix.packages.mini-agenix
    inputs'.nixos-anywhere.packages.nixos-anywhere
    nh
    nix
    age
  ];

  NIX_CONFIG = "plugin-files = ${inputs'.mini-agenix.packages.mini-agenix}/lib/libmini_agenix.so";
}
