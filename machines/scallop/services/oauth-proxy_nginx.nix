{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.services.oauth2-proxy.nginx;
in {
  options = {
    services.oauth2-proxy.nginx.virtualHostsWithGroups = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = lib.mdDoc ''
        A list of nginx virtual hosts to put behind the oauth2 proxy, with optional group restrictions
      '';
    };
  };

  config.services = {
    oauth2-proxy.nginx.domain = "seashell.social";
    nginx = lib.mkIf config.services.oauth2-proxy.enable (lib.mkMerge
      ((lib.optional (cfg.virtualHostsWithGroups != []) {
          recommendedProxySettings = true; # needed because duplicate headers
        })
        ++ (map ({
            vhost,
            groups ? [],
          }: {
            virtualHosts.${vhost} = {
              locations."/oauth2/" = {
                proxyPass = cfg.proxy;
                extraConfig = ''
                  proxy_set_header X-Scheme                $scheme;
                  proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
                '';
              };
              locations."/oauth2/auth" = {
                proxyPass = cfg.proxy;
                extraConfig = ''
                  rewrite ^ /oauth2/auth?allowed_groups=${builtins.concatStringsSep "," groups} break;
                  proxy_set_header X-Scheme         $scheme;
                  # nginx auth_request includes headers but not body
                  proxy_set_header Content-Length   "";
                  proxy_pass_request_body           off;
                '';
              };
              locations."/".extraConfig = ''
                auth_request /oauth2/auth;
                error_page 401 = /oauth2/sign_in;
                # pass information via X-User and X-Email headers to backend,
                # requires running with --set-xauthrequest flag
                auth_request_set $user   $upstream_http_x_auth_request_user;
                auth_request_set $email  $upstream_http_x_auth_request_email;
                proxy_set_header X-User  $user;
                proxy_set_header X-Email $email;
                # if you enabled --cookie-refresh, this is needed for it to work with auth_request
                auth_request_set $auth_cookie $upstream_http_set_cookie;
                add_header Set-Cookie $auth_cookie;
              '';
            };
          })
          cfg.virtualHostsWithGroups)));
  };
}
