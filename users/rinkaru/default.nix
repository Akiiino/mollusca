{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  users.users.rinkaru = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/rinkaru.pub")
    ];
  };
}
