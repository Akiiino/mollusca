{self, ...}: {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import "${self}/overlays" {flake = self;};
  };
  nix.settings.experimental-features = ["nix-command" "flakes"];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
