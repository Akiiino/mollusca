{flake}: [
  (import ./hydroxide.nix)
  (import ./nextcloud.nix)
  (import ./libreddit.nix)
  (import ./grocy.nix {inherit flake;})
]
