{
  config,
  pkgs,
  lib,
  ...
}:
{
  mollusca.useTailscale = true;
  mollusca.isExitNode = true;
  environment.persistence."/persist".directories = lib.singleton {
    directory = "/var/lib/tailscale";
    user = "root";
    group = "root";
    mode = "u=rwx,g=,o=";
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
