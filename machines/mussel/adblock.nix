{
  self,
  config,
  lib,
  ...
}:
{
  services.coredns = {
    enable = true;
    config = ''
      . {
        hosts ${self.inputs.stevenBlackHosts}/hosts {
          fallthrough
        }
        # Cloudflare Forwarding
        forward . 1.1.1.1 1.0.0.1
        cache
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
