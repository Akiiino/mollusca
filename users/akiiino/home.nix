{
  pkgs,
  config,
  ...
}:
{
  home = {
    packages = with pkgs; [
      gimp
      tdesktop
      signal-desktop
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
      openscad-unstable
      freecad-wayland
      prusa-slicer

      gdu
      htop
      fdupes
      koreader
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

    stateVersion = "22.05";
  };
  xdg = {
    enable = true;
    configHome = config.home.homeDirectory + "/Configuration";
    dataHome = config.home.homeDirectory + "/Data";
    stateHome = config.home.homeDirectory + "/State";
  };
  programs = {
    kakoune.enable = true;
    bash.enable = true;
    zsh.enable = true;
    fzf.enable = true;
  };
}
