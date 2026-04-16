{
  pkgs,
  self,
  ...
}:
{
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "scanner"
      "lp"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
    ];
  };
}
