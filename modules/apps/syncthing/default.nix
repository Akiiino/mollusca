{
  config,
  pkgs,
  lib,
  self,
  osConfig,
  ...
}:
{
  services.syncthing = {
    enable = true;
  };
}
