{
  self,
  pkgs,
  inputs',
  ...
}:
{
  home-manager.users.akiiino =
    { config, ... }:
    {
      imports = [
        "${self}/modules/home/firefox.nix"
        "${self}/modules/home/kitty.nix"
        "${self}/modules/home/mpv.nix"
        "${self}/modules/desktop/niri/home.nix"
        "${self}/modules/desktop/theming/home.nix"
      ];

      programs.kitty.settings.kitty_mod = "ctrl+shift";

      home.packages = [
        pkgs.gimp
        pkgs.dolphin-emu
        pkgs.vlc
        pkgs.shotwell
        pkgs.localsend
        pkgs.openscad-unstable
        pkgs.prusa-slicer
        pkgs.nomacs
        pkgs.koreader
        pkgs.gyre-fonts
        pkgs.trayscale
        pkgs.cheese
        pkgs.usbutils
        pkgs.btdu
        pkgs.kdePackages.partitionmanager
        pkgs.kdePackages.skanlite
        pkgs.evince
        pkgs.android-tools-xdg
        pkgs.yubikey-manager
        pkgs.yubico-piv-tool
        pkgs.obsidian
        pkgs.tor-browser
        inputs'.filewatcher123d.packages.filewatcher123d

        (pkgs.kdePackages.skanpage.override {
          tesseractLanguages = [
            "eng"
            "deu"
            "rus"
          ];
        })
      ];

      xdg = {
        terminal-exec = {
          enable = true;
          settings.default = [ "kitty.desktop" ];
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
              text = "kakoune.desktop";
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

        # Keep config/data/state in visible, plainly-named dirs instead of
        # hidden dotdirs.
        configHome = config.home.homeDirectory + "/Configuration";
        dataHome = config.home.homeDirectory + "/Data";
        stateHome = config.home.homeDirectory + "/State";
      };

      # Back-compat for apps that hardcode the default XDG paths: symlink them
      # to the relocated dirs; the .keep files force the targets to exist.
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
