{
  self,
  pkgs,
  lib,
  ...
}:
{
  home-manager.users.akiiino =
    { config, ... }:
    {
      imports = [
        "${self}/modules/home/syncthing.nix"
      ];

      home.packages = [
        pkgs.telegram-desktop
        pkgs.signal-desktop
        pkgs.spotify
        pkgs.keepassxc
        pkgs.discord
        pkgs.proton-vpn
        pkgs.tremotesf
        pkgs.yafc-ce
      ];

      programs.thunderbird.enable = true;

      xdg = {
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
    };
}
