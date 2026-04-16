{
  self,
  ...
}:
{
  home-manager.users.akiiino = {
    imports = [
      "${self}/modules/apps/direnv.nix"
      "${self}/modules/apps/firefox"
      "${self}/modules/apps/git.nix"
      "${self}/modules/apps/kakoune"
      "${self}/modules/apps/kitty.nix"
      "${self}/modules/apps/starship.nix"
      "${self}/modules/apps/syncthing"
      "${self}/modules/apps/zsh.nix"
      "${self}/users/akiiino/home.nix"
    ];
    programs.kitty.settings.kitty_mod = "ctrl+shift";
  };
}
