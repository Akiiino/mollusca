{ pkgs, config, ... }: {
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
  ];
  programs.kakoune.enable = true;
  programs.bash.enable = true;
  programs.zsh.enable = true;

  home.stateVersion = "22.05";
}
