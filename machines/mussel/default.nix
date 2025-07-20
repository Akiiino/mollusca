{
  self,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${self}/modules/raspberrypi.nix"
    ./adblock.nix
  ];

  mollusca.isRemote = true;

  networking.hostName = "mussel";
  networking.domain = "";

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.uid = 995;
  users.groups.jellyfin.gid = 993;
  fileSystems."/mnt/Media" = self.lib.mkCifs {
    location = "192.168.1.225/Media";
    uid = builtins.toString config.users.users.jellyfin.uid;
    gid = builtins.toString config.users.groups.jellyfin.gid;
  };
  networking.firewall.allowedTCPPorts = [
    8080
    8081
  ];
}
