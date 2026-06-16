{
  self,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  home-manager.users.akiiino =
    { config, ... }: # TODO: this feels ugly
    {
      imports = [
        inputs.walker.homeManagerModules.default
        "${self}/modules/apps/desktop-shell.nix"
        "${self}/modules/apps/firefox"
        "${self}/modules/apps/kitty.nix"
        "${self}/modules/apps/mpv.nix"
        "${self}/modules/apps/niri"
      ];

      programs.kitty.settings.kitty_mod = "ctrl+shift";

      home.packages = with pkgs; [
        gimp
        dolphin-emu
        vlc
        shotwell
        localsend
        openscad-unstable
        prusa-slicer
        nomacs
        koreader
        gyre-fonts
        pkgs.trayscale
        pkgs.cheese
        pkgs.usbutils
        pkgs.btdu
        pkgs.kdePackages.partitionmanager
        pkgs.kdePackages.skanlite
        pkgs.evince
        (pkgs.kdePackages.skanpage.override {
          tesseractLanguages = [
            "eng"
            "deu"
            "rus"
          ];
        })
        pkgs.android-tools-xdg
        pkgs.yubikey-manager
        pkgs.yubico-piv-tool
      ];

      xdg = {
        desktopEntries.kakoune-kitty = {
          name = "Kakoune (via Kitty)";
          genericName = "Text Editor";
          exec = "${lib.getExe pkgs.kitty} ${lib.getExe pkgs.mollusca.kakoune} %F";
          terminal = false; # TODO: is this necessary?
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

        mimeApps = {
          enable = true;
          defaultApplications =
            let
              images = "org.gnome.Shotwell-Viewer.desktop";
              av = "vlc.desktop";
              browser = "firefox.desktop";
              mail = "thunderbird.desktop";
              files = "org.xfce.thunar.desktop";
              archive = "org.kde.ark.desktop";
              text = "kakoune-kitty.desktop";
            in
            {
              "application/pdf" = "org.gnome.Evince.desktop";

              "text/plain" = text;
              "text/markdown" = text;
              "text/csv" = text;
              "application/json" = text;

              "image/jpeg" = images;
              "image/png" = images;
              "image/gif" = images;
              "image/webp" = images;
              "image/bmp" = images;
              "image/tiff" = images;

              "video/mp4" = av;
              "video/mpeg" = av;
              "video/webm" = av;
              "video/x-matroska" = av;
              "video/x-msvideo" = av;
              "video/quicktime" = av;
              "video/ogg" = av;
              "audio/mpeg" = av;
              "audio/flac" = av;
              "audio/ogg" = av;
              "audio/wav" = av;
              "audio/x-wav" = av;
              "audio/mp4" = av;

              "text/html" = browser;
              "application/xhtml+xml" = browser;
              "x-scheme-handler/http" = browser;
              "x-scheme-handler/https" = browser;
              "x-scheme-handler/about" = browser;
              "x-scheme-handler/unknown" = browser;

              "x-scheme-handler/mailto" = mail;
              "message/rfc822" = mail;
              "application/x-extension-eml" = mail;

              "inode/directory" = files;

              "application/zip" = archive;
              "application/x-tar" = archive;
              "application/x-compressed-tar" = archive;
              "application/x-bzip2-compressed-tar" = archive;
              "application/x-xz-compressed-tar" = archive;
              "application/gzip" = archive;
              "application/x-7z-compressed" = archive;
              "application/vnd.rar" = archive;
              "application/x-rar" = archive;
            };
        };
      };
    };
}
