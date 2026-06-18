{ minor-secrets, ... }:
let
  dav = {
    proxyPass = "http://[::1]:4000";
    proxyWebsockets = true; # WebDAV-Push
  };
in
{
  services.rustical = {
    enable = true;
    settings.http = {
      host = "[::]";
      port = 4000;
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 4000 ];

  services.nginx.virtualHosts."dav.${minor-secrets.personalDomain}" = {
    forceSSL = true;
    useACMEHost = minor-secrets.personalDomain;
    locations = {
      "/.well-known/caldav" = dav;
      "/.well-known/carddav" = dav;
      "/caldav" = dav;
      "/caldav-compat" = dav;
      "/carddav" = dav;
      "/carddav-compat" = dav;

      # Frontend / everything else is not public.
      "/".extraConfig = "return 404;";
    };
  };
}
