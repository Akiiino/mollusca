# lan-services.nix — Expose LAN services to LAN + Tailscale peers.
#
# nginx runs as a reverse proxy on actinella and routes by Host header to
# the actual backend.  A single CoreDNS instance serves the same answers to
# everyone (no split-horizon): each service name resolves to actinella's LAN
# address, with ad-blocking applied for all clients.
#
# How names resolve (one answer everywhere)
# ──────────────────────────────────────────
#   Every service host → `lanAddress` (e.g. 192.168.1.101), for LAN clients
#   and Tailscale peers alike.  CoreDNS listens on all interfaces, so the
#   same records are served on the LAN IP and the Tailscale IP without any
#   runtime IP discovery.
#
#   • LAN clients reach `lanAddress` directly.
#   • Tailscale peers reach `lanAddress` because actinella advertises it as a
#     subnet route (`mollusca.advertiseRoutes = [ "192.168.1.101/32" ]`), and
#     peers `--accept-routes`.  RFC1918 ⇒ the address is unroutable from the
#     internet, so these services are private by construction.
#
# Setup (one-time)
# ────────────────
#   • Tailscale admin → DNS → Split DNS: one restricted-nameserver entry,
#       Domain:     <your domain>   Nameserver: <actinella's Tailscale IP>
#     so remote peers send those queries to this resolver.
#   • Tailscale admin → approve the advertised subnet route from actinella.

{
  config,
  lib,
  ...
}:

let
  cfg = config.mollusca.lanServices;

  serviceHosts = builtins.attrNames cfg.services;

  # ── Hosts entries for the CoreDNS block ───────────────────────────
  lanHostsLines = lib.concatMapStringsSep "\n" (
    host: "        ${cfg.lanAddress} ${host}"
  ) serviceHosts;

  # ── Extra static DNS records (non-proxied) ────────────────────────
  extraHostsLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (host: ip: "        ${ip} ${host}") cfg.extraDnsRecords
  );

  allLanHostsLines = lib.concatStringsSep "\n" (
    lib.filter (s: s != "") [
      lanHostsLines
      extraHostsLines
    ]
  );

  blocklistDirective = if cfg.blocklist != null then "hosts ${cfg.blocklist}" else "hosts";

  # ── CoreDNS Corefile (single view) ────────────────────────────────
  # No `bind` directive: CoreDNS listens on all interfaces, so the same
  # answers are served on the LAN IP and the Tailscale IP. The hosts block
  # serves the blocklist + our internal records; everything else is
  # forwarded upstream.
  corefile = ''
    .:53 {
      ${blocklistDirective} {
    ${allLanHostsLines}
        ttl 30
        fallthrough
      }
      forward . ${cfg.upstreamDNS}
      cache
    }
  '';

  serviceModule = lib.types.submodule {
    options = {
      proxyPass = lib.mkOption {
        type = lib.types.str;
        description = "Backend URL (e.g. \"http://192.168.1.204\" or \"http://127.0.0.1:8096\").";
      };
      websocket = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable WebSocket proxying for this service.";
      };
      extraLocationConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra nginx location directives.";
      };
    };
  };

in
{

  # ═══════════════════════════════════════════════════════════════════
  # Options
  # ═══════════════════════════════════════════════════════════════════

  options.mollusca.lanServices = {

    enable = lib.mkEnableOption "LAN service exposure via nginx + Tailscale DNS";

    lanAddress = lib.mkOption {
      type = lib.types.str;
      description = "This machine's LAN IPv4 address.";
      example = "192.168.1.101";
    };

    acmeHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        If set, serve every virtual host over HTTPS using this ACME
        certificate (passed as nginx `useACMEHost`).  The certificate
        must already be provisioned (e.g. a wildcard via security.acme).
        nginx is added to the `acme` group automatically.
      '';
      example = "akiiino.me";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf serviceModule;
      default = { };
      description = ''
        Services to expose.  Keys are fully qualified hostnames.
        Each gets an nginx virtual host and a DNS record.
      '';
      example = lib.literalExpression ''
        {
          "jellyfin.akiiino.me" = {
            proxyPass = "http://127.0.0.1:8096";
            websocket = true;
          };
          "valetudo.akiiino.me" = {
            proxyPass = "http://192.168.1.204";
          };
        }
      '';
    };

    extraDnsRecords = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Additional hostname → IP mappings for DNS only.
        These are NOT proxied by nginx — they resolve directly
        to the given IP.  Useful for devices that aren't
        HTTP services (printers, MQTT brokers, etc.).
      '';
      example = {
        "printer.akiiino.me" = "192.168.1.50";
      };
    };

    blocklist = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a hosts-format blocklist (e.g. Steven Black).
        Applied to all DNS clients.
      '';
    };

    upstreamDNS = lib.mkOption {
      type = lib.types.str;
      default = "1.1.1.1 1.0.0.1";
      description = "Upstream DNS servers for CoreDNS forwarding.";
    };
  };

  # ═══════════════════════════════════════════════════════════════════
  # Implementation
  # ═══════════════════════════════════════════════════════════════════

  config = lib.mkIf cfg.enable {

    # ── nginx reverse proxy ─────────────────────────────────────────

    services.nginx = {
      enable = true;

      # Sane defaults for reverse proxying
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = lib.mapAttrs (
        _host: svc:
        {
          locations."/" = {
            inherit (svc) proxyPass;
            proxyWebsockets = svc.websocket;
            extraConfig = svc.extraLocationConfig;
          };
        }
        // lib.optionalAttrs (cfg.acmeHost != null) {
          forceSSL = true;
          useACMEHost = cfg.acmeHost;
        }
      ) cfg.services;
    };

    users.users.nginx.extraGroups = lib.optionals (cfg.acmeHost != null) [ "acme" ];

    # ── Firewall ────────────────────────────────────────────────────

    networking.firewall = {
      allowedTCPPorts = [
        53
        80
        443
      ];
      allowedUDPPorts = [ 53 ];
    };

    # ── CoreDNS (single view, all interfaces) ───────────────────────

    services.coredns = {
      enable = true;
      config = corefile;
    };
  };
}
