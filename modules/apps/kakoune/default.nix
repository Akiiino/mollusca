{
  pkgs,
  lib,
  config,
  ...
}:
{
  xdg.desktopEntries = lib.mkIf config.xdg.terminal-exec.enable {
    kakoune = {
      name = "Kakoune";
      genericName = "Text Editor";
      exec = "${lib.getExe pkgs.mollusca.kakoune} %F";
      terminal = true;
      categories = [
        "Utility"
        "TextEditor"
      ];
      mimeType = [
        "text/plain"
        "text/markdown"
        "text/csv"
        "application/json"
      ];
    };
  };
  home.packages = [ pkgs.mollusca.kakoune ];
  home.sessionVariables.EDITOR = lib.getExe pkgs.mollusca.kakoune;
}
