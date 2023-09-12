{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.tailscale];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };
}
