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
        "${self}/modules/apps/firefox.nix"
        "${self}/modules/apps/git.nix"
        "${self}/modules/apps/kitty.nix"
        "${self}/modules/apps/gnome.nix"
        "${self}/modules/apps/direnv.nix"
        "${self}/users/akiiino/home.nix"
      ];
    });
  };
}
