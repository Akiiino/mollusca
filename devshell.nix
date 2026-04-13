{
  pkgs,
  inputs,
  inputs',
  system,
  ...
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

  NIX_CONFIG = inputs.mini-agenix.lib."${system}".nixConfig;
}
