{
  self,
  config,
  minor-secrets,
  ...
}:
{
  mollusca.useDefaultDomain = true;
  services.tailscale.derper = {
    enable = true;
    domain = "${minor-secrets.derpDomain}";
    verifyClients = true;
  };

  services.nginx.virtualHosts."${minor-secrets.derpDomain}" = {
    useACMEHost = minor-secrets.personalDomain;
  };

  users.users.nginx.extraGroups = [ "acme" ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
