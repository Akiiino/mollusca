{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    gimp
    tdesktop
    spotify
    keepassxc
    discord
    protonvpn-gui
    obsidian
    dolphin-emu
    vlc
    libreoffice
    shotwell
    gyre-fonts
    localsend
    openscad
    freecad-wayland
    prusa-slicer

    gdu
    htop
    fdupes
    koreader
  ];
  home.file = {
    ".local/share".source = config.lib.file.mkOutOfStoreSymlink (config.xdg.dataHome);
    "${config.xdg.dataHome}/.keep".text = "";

    ".config".source = config.lib.file.mkOutOfStoreSymlink (config.xdg.configHome);
    "${config.xdg.configHome}/.keep".text = "";

    ".local/state".source = config.lib.file.mkOutOfStoreSymlink (config.xdg.stateHome);
    "${config.xdg.stateHome}/.keep".text = "";
  };
  xdg = {
    enable = true;
    configHome = config.home.homeDirectory + "/Configuration";
    dataHome = config.home.homeDirectory + "/Data";
    stateHome = config.home.homeDirectory + "/State";
  };
  programs.kakoune.enable = true;
  programs.bash.enable = true;
  programs.zsh.enable = true;
  home.language.base = "en_US.UTF-8";

  home.stateVersion = "22.05";
}
