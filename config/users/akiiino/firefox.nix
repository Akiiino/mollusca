{ config, pkgs, lib, nur, ... }:

{
  programs.firefox = {
    enable = true;
    #extensions = with nur.repos.rycee.firefox-addons; [
    #  clearurls
    #  cookie-autodelete
    #  keepass-helper
    #  reddit-enhancement-suite
    #  tree-style-tab
    #  ublock-origin
    #  vimium
    #];
    profiles = {
      akiiino = {
        id = 0;
        name = "akiiino";
        settings = {
          "browser.startup.homepage" = "about:blank";
        };
      };
    };
  };
}
