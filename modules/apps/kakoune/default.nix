{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [ pkgs.mollusca.kakoune ];
  home.sessionVariables.EDITOR = lib.getExe pkgs.mollusca.kakoune;
}
