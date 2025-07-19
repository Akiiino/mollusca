{self, ...}: {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import "${self}/overlays" {flake = self;};
    config.permittedInsecurePackages = [
      "nextcloud-28.0.14"
    ];
  };
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    use-xdg-base-directories = true;
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
