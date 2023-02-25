{ config, pkgs, lib, ... }:

{
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ];
    hashedPassword =
      "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuSVZxW6Thf5YNnCk9n7k1R/Dug637YgvTAlmqNloKcHXbOGCWU7zxE3WwQU2GRDMsq5tTypO8StvLmNeD7LwIbXEUBWBxKETfcr8gDNfr33z2icPD8yn9xsFkZEg48O9iN3o+DByPmbn06D7Xru4vKLWXsq33tp3qlqEOFqXezwmyo17knIAHwoEVLjM/VLvmUsOjWcOMwUMPkG6IljIwRhTdNyjeWrL43iHEfs6Z0zc3kzzFZVgsTLqa6r/Yu6PUr9ZgBDdDvxaLeqX07UPghO+OXDG1TeN7uQVnCUopDk9jEs0p4tI/uPwgqCLirDZ3p7Yx+gLPAMKVktbD/5M90fL4YPeCXbo7GxbRyjol9GtOa0tZ3I9LljMDEThDY5wLVCDMCGrrg8FGqrZkm4L6gVjFMIblO2IGz5CNh8gCLXUM2+LkmkN/wyTvP7mUYs+j4VmRlNCKvmrP78UH+KhO5osxdqCEhTWx9N4iPqnW2AAjuEOQzvWeP0gOMrfEejs= akiiino@gastropod"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYtvcJekwubXWEcQ66Vby83p7bHPriY6RKwuJ5P1eE4 akiiino@gastropod"
    ];
  };
}
