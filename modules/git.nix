{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "akiiino";
    userEmail = "git@akiiino.me";
  };
}
