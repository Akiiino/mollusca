{ minor-secrets, ... }:
{
  services.nginx.virtualHosts."photos.${minor-secrets.personalDomain}" = {
    forceSSL = true;
    useACMEHost = minor-secrets.personalDomain;
    locations."/" = {
      proxyPass = "http://actinella:8300";
      proxyWebsockets = true;
    };
  };
}
