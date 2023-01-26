{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
    
  ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "scallop";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuSVZxW6Thf5YNnCk9n7k1R/Dug637YgvTAlmqNloKcHXbOGCWU7zxE3WwQU2GRDMsq5tTypO8StvLmNeD7LwIbXEUBWBxKETfcr8gDNfr33z2icPD8yn9xsFkZEg48O9iN3o+DByPmbn06D7Xru4vKLWXsq33tp3qlqEOFqXezwmyo17knIAHwoEVLjM/VLvmUsOjWcOMwUMPkG6IljIwRhTdNyjeWrL43iHEfs6Z0zc3kzzFZVgsTLqa6r/Yu6PUr9ZgBDdDvxaLeqX07UPghO+OXDG1TeN7uQVnCUopDk9jEs0p4tI/uPwgqCLirDZ3p7Yx+gLPAMKVktbD/5M90fL4YPeCXbo7GxbRyjol9GtOa0tZ3I9LljMDEThDY5wLVCDMCGrrg8FGqrZkm4L6gVjFMIblO2IGz5CNh8gCLXUM2+LkmkN/wyTvP7mUYs+j4VmRlNCKvmrP78UH+KhO5osxdqCEhTWx9N4iPqnW2AAjuEOQzvWeP0gOMrfEejs= akiiino@gastropod"
  ];
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "22.05";

  environment.systemPackages = with pkgs; [
      kakoune
  ];
}
