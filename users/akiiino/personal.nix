{
  self,
  pkgs,
  inputs',
  lib,
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
        yafc-ce
      ];

      programs.thunderbird.enable = true;

      xdg = {
        configHome = config.home.homeDirectory + "/Configuration";
        dataHome = config.home.homeDirectory + "/Data";
        stateHome = config.home.homeDirectory + "/State";

        dataFile."icons/hicolor/64x64/apps/yafc.png".source =
          pkgs.runCommand "yafc-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; }
            ''
              magick "${pkgs.yafc-ce}/lib/yafc-ce/image.ico" "$out"
            '';
        desktopEntries.yafc = {
          name = "YAFC";
          genericName = "Factorio Production Calculator";
          exec = lib.getExe pkgs.yafc-ce;
          icon = "yafc";
          categories = [ "Utility" ];
        };

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
