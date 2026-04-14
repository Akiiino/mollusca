# lan-services.nix — Expose LAN services to Tailscale peers via nginx + DNS.
#
# Instead of advertising the whole LAN as a Tailscale subnet route, this
# module runs nginx as a reverse proxy on actinella.  Tailscale peers
# connect to actinella's Tailscale IP; nginx routes by Host header to
# the actual backend.  A single CoreDNS instance serves both LAN and
# Tailscale clients, with ad-blocking on the LAN side.
#
# Setup (one-time)
# ────────────────
#   In the Tailscale admin console → DNS → Nameservers, add a
#   Split DNS entry:
#     Domain:      akiiino.me   (or whatever you set as `domain`)
#     Nameserver:  <actinella's Tailscale IP>  (`tailscale ip -4`)
#
# How it works
# ────────────
#   LAN client                          Tailscale peer
#       │                                    │
#       │ DNS: jellyfin.akiiino.me?          │ DNS (split): jellyfin.akiiino.me?
#       ▼                                    ▼
#   CoreDNS (192.168.1.101)           CoreDNS (Tailscale IP)
#   answers: 192.168.1.101            answers: <Tailscale IP>
#       │                                    │
#       ▼                                    ▼
#   nginx ──► proxy_pass backend     nginx ──► proxy_pass backend
#
#   Both paths hit the same nginx, which routes by Host header.
#   No subnet route required — only actinella is reachable.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mollusca.lanServices;

  serviceHosts = builtins.attrNames cfg.services;

  # ── Hosts entries for the LAN CoreDNS block ───────────────────────
  lanHostsLines = lib.concatMapStringsSep "\n" (
    host: "        ${cfg.lanAddress} ${host}"
  ) serviceHosts;

  # ── Extra static DNS records (non-proxied, LAN only) ──────────────
  extraHostsLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (host: ip: "        ${ip} ${host}") cfg.extraDnsRecords
  );

  allLanHostsLines = lib.concatStringsSep "\n" (
    lib.filter (s: s != "") [
      lanHostsLines
      extraHostsLines
    ]
  );

  # ── CoreDNS Corefile template ─────────────────────────────────────
  # TAILSCALE_IP is replaced at runtime by the wrapper script.
  # The LAN block is always present; the Tailscale block is only
  # included when a Tailscale IP is available.

  blocklistDirective = if cfg.blocklist != null then "hosts ${cfg.blocklist}" else "hosts";

  lanBlock = ''
    .:53 {
      bind 127.0.0.1 ${cfg.lanAddress}
      ${blocklistDirective} {
    ${allLanHostsLines}
        fallthrough
      }
      forward . ${cfg.upstreamDNS}
      cache
    }
  '';

  tsBlock = ''
    .:53 {
      bind TAILSCALE_IP
      hosts /run/lan-services-dns/ts-hosts {
        fallthrough
      }
      forward . ${cfg.upstreamDNS}
      cache
    }
  '';

  corefileFull = pkgs.writeText "Corefile.full" ''
    ${lanBlock}
    ${tsBlock}
  '';

  corefileLanOnly = pkgs.writeText "Corefile.lan-only" lanBlock;

  # ── Shell fragments for writing the Tailscale hosts file ──────────
  tsHostsWriteLines = lib.concatMapStringsSep "\n" (
    host: ''echo "$TS_IP ${host}" >> "$RD/ts-hosts"''
  ) serviceHosts;

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
        Additional hostname → IP mappings for LAN DNS only.
        These are NOT proxied by nginx — they resolve directly
        to the given IP.  Useful for devices that aren't
        HTTP services (printers, etc.).
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
        Applied only to the LAN DNS listener, not to Tailscale peers.
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

    assertions = [
      {
        assertion = !config.services.coredns.enable;
        message = ''
          mollusca.lanServices manages its own CoreDNS instance.
          Remove or disable services.coredns to avoid conflicts.
        '';
      }
    ];

    # ── nginx reverse proxy ─────────────────────────────────────────

    services.nginx = {
      enable = true;

      # Sane defaults for reverse proxying
      recommendedProxySettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = lib.mapAttrs (_host: svc: {
        locations."/" = {
          inherit (svc) proxyPass;
          proxyWebsockets = svc.websocket;
          extraConfig = svc.extraLocationConfig;
        };
      }) cfg.services;
    };

    # ── Firewall ────────────────────────────────────────────────────

    networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
      allowedTCPPorts = [
        53
        80
      ];
      allowedUDPPorts = [ 53 ];
    };

    # ── CoreDNS (unified LAN + Tailscale) ───────────────────────────

    systemd.services.lan-services-dns = {
      description = "CoreDNS — LAN (with ad-blocking) + Tailscale";
      after = [
        "tailscaled.service"
        "network.target"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      path = [ config.services.tailscale.package ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
        RuntimeDirectory = "lan-services-dns";
        DynamicUser = true;
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      };

      script = ''
        set -euo pipefail
        RD="$RUNTIME_DIRECTORY"

        # Try to get Tailscale IP (up to 60 s).
        TS_IP=""
        for _ in $(seq 1 30); do
          TS_IP=$(tailscale ip -4 2>/dev/null || true)
          [ -n "$TS_IP" ] && break
          sleep 2
        done

        if [ -n "$TS_IP" ]; then
          echo "Tailscale IP: $TS_IP — enabling Tailscale DNS block"

          # Build the Tailscale-side hosts file at runtime.
          : > "$RD/ts-hosts"
        ${tsHostsWriteLines}

          sed "s/TAILSCALE_IP/$TS_IP/g" ${corefileFull} > "$RD/Corefile"
        else
          echo "Warning: Tailscale IP not available — LAN DNS only"
          cp ${corefileLanOnly} "$RD/Corefile"
        fi

        exec ${pkgs.coredns}/bin/coredns -conf "$RD/Corefile"
      '';
    };
  };
}
