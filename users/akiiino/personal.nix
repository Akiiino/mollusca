{
  self,
  pkgs,
  inputs',
  ...
}:
{
  home-manager.users.akiiino =
    { config, ... }: # TODO: this feels ugly
    {
      imports = [
        "${self}/modules/apps/syncthing"
      ];

      home.packages = with pkgs; [
        telegram-desktop
        signal-desktop
        spotify
        keepassxc
        discord
        proton-vpn
        obsidian
        tremotesf
        inputs'.filewatcher123d.packages.filewatcher123d
      ];

      programs.thunderbird.enable = true;

      xdg = {
        configHome = config.home.homeDirectory + "/Configuration";
        dataHome = config.home.homeDirectory + "/Data";
        stateHome = config.home.homeDirectory + "/State";
      };

      home.file = {
        ".local/share".source = config.lib.file.mkOutOfStoreSymlink config.xdg.dataHome;
        "${config.xdg.dataHome}/.keep".text = "";

        ".config".source = config.lib.file.mkOutOfStoreSymlink config.xdg.configHome;
        "${config.xdg.configHome}/.keep".text = "";

        ".local/state".source = config.lib.file.mkOutOfStoreSymlink config.xdg.stateHome;
        "${config.xdg.stateHome}/.keep".text = "";
      };
    };
}
