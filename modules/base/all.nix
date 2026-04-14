{
  self,
  pkgs,
  inputs,
  inputs',
  minor-secrets,
  lib,
  ...
}:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = import "${self}/overlays";
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
    channel.enable = false;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        self
        inputs
        inputs'
        minor-secrets
        ;
    };
    backupFileExtension = "backup";
  };

  time.timeZone = lib.mkDefault "Europe/Berlin";

  programs.zsh.enable = true;
}
