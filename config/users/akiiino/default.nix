{ config, pkgs, lib, ... }:

{
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ]; # Enable ‘sudo’ for the user.
    hashedPassword = "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
  };

  home-manager.users.akiiino = { pkgs, nur, ... }: {
    imports = [
      ../../modules/firefox.nix
      ../../modules/git.nix
      ../../modules/kitty.nix
      ../../modules/gnome.nix
      ./home.nix
    ];
  };
}
