{ self, pkgs, inputs', ... }:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import "${self}/overlays" { flake = self; };
  };
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      use-xdg-base-directories = true;
      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
    };
    extraOptions = ''
      extra-nix-path = nixpkgs=flake:nixpkgs
    '';
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit self inputs'; };
    backupFileExtension = "backup";
  };
  fonts.packages = [
    pkgs.fira-code
    pkgs.nerd-fonts.hack
    pkgs.iosevka
  ];
  programs.zsh.enable = true;
}
