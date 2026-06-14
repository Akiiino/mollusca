{
  pkgs,
  config,
  inputs',
  lib,
  ...
}:
{
  home = {
    packages = with pkgs; [
      gimp
      telegram-desktop
      signal-desktop
      spotify
      keepassxc
      discord
      proton-vpn
      obsidian
      dolphin-emu
      vlc
      shotwell
      gyre-fonts
      localsend
      openscad-unstable
      prusa-slicer
      thunderbird
      tremotesf
      inputs'.filewatcher123d.packages.filewatcher123d

      gdu
      htop
      fdupes
      koreader
      nomacs
    ];
    file = {
      ".local/share".source = config.lib.file.mkOutOfStoreSymlink config.xdg.dataHome;
      "${config.xdg.dataHome}/.keep".text = "";

      ".config".source = config.lib.file.mkOutOfStoreSymlink config.xdg.configHome;
      "${config.xdg.configHome}/.keep".text = "";

      ".local/state".source = config.lib.file.mkOutOfStoreSymlink config.xdg.stateHome;
      "${config.xdg.stateHome}/.keep".text = "";
    };
    language.base = "en_US.UTF-8";

    sessionVariables = {
      XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
      GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
      ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
    };

    stateVersion = "22.05";
  };

  xdg = {
    enable = true;
    configHome = config.home.homeDirectory + "/Configuration";
    dataHome = config.home.homeDirectory + "/Data";
    stateHome = config.home.homeDirectory + "/State";

    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true; # TODO: this is a legacy value. What breaks if I change to `false` - the new default?
    };

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
  programs = {
    bash.enable = true;
    zsh.enable = true;
    fzf.enable = true;
  };
}
