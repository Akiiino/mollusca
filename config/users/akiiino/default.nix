{ config, pkgs, lib, ... }:

{
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [ "wheel" "adbusers" ];
    hashedPassword =
      "$6$nwRe8GAT99X9XVMD$EI8wRSBQF.zw6Evh7UVFKxfu/K9v2.i4hb1unxSnf26e50glpz6SkuVR9MQYr7/m.1IqgrstKvnPAVPa1i/JB0";
  };

}
