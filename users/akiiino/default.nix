{
  config,
  pkgs,
  lib,
  ...
}: {
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = ["wheel" "adbusers"];
    hashedPassword = "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYtvcJekwubXWEcQ66Vby83p7bHPriY6RKwuJ5P1eE4 akiiino@gastropod"
    ];
  };
}
