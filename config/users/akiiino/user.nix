{ config, pkgs, lib, ... }:

{
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ]; # Enable ‘sudo’ for the user.
    hashedPassword = "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
  };

  home-manager.users.akiiino = { pkgs, ... }: {
    imports = [
      ./firefox.nix
      ./git.nix
      ./kitty.nix
      ./gnome.nix
    ];

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
      slack
      libreoffice
      shotwell
    ];
    programs.kakoune.enable = true;
    programs.bash.enable = true;
    programs.zsh.enable = true;

    home.stateVersion = "22.05";
  };

}
