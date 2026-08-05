{
  self,
  ...
}:
{
  home-manager.users.akiiino = _: {
    imports = [
      "${self}/modules/desktop/niri/home.nix"
    ];
  };
}
