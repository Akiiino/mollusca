{self, ...}: {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import "${self}/overlays" {flake = self;};
  };
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];

    registry.nixpkgs.flake = self.inputs.nixpkgs;
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
