{
  config,
  pkgs,
  lib,
  self,
  ...
}: {
  options.mollusca = {
    enableHM = lib.mkEnableOption "home-manager environment";
  };
  config = {
    users.users.akiiino = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        (builtins.readFile "${self}/secrets/keys/akiiino.pub")
      ];
    };
    home-manager.users.akiiino = lib.mkIf config.mollusca.enableHM ({...}: {
      imports = [
        "${self}/users/akiiino/modules/firefox.nix"
        "${self}/users/akiiino/modules/git.nix"
        "${self}/users/akiiino/modules/kitty.nix"
        "${self}/users/akiiino/modules/gnome.nix"
        "${self}/users/akiiino/home.nix"
      ];
    });
  };
}
