# TV Network Filter — NixOS module
#
# Turns a Raspberry Pi (or any NixOS machine with two network interfaces)
# into a filtering gateway for a smart TV.  The TV connects via Ethernet
# to the Pi; the Pi connects to the internet via Wi-Fi.  Only explicitly
# allowlisted domains and IPs are reachable from the TV.
#
# ┌────┐  ethernet   ┌──────────────┐  wi-fi       ┌──────────┐
# │ TV ├────────────►│ Raspberry Pi ├─────────────►│ Internet │
# └────┘  (tvIface)  └──────────────┘  (wanIface)  └──────────┘
#
# Architecture
# ────────────
#   • dnsmasq  — runs a dedicated instance on the TV-facing interface.
#                Provides DHCP (so the TV auto-configures) and DNS.
#                All domains are blocked by default (resolve to 0.0.0.0);
#                allowlisted domains are forwarded to an upstream resolver.
#                Resolved IPs are pushed into an nftables set via --nftset
#                so the firewall can allow them dynamically.
#
#   • nftables — a self-contained table (inet tv_filter) that:
#                · drops all forwarded traffic from the TV except to IPs in
#                  the dynamic set (DNS-resolved) or the static set;
#                · redirects (DNATs) external DNS from the TV to the
#                  local dnsmasq, so hardcoded DNS servers are filtered;
#                · drops external DNS in forward as a safety net;
#                · drops all IPv6 from the TV;
#                · masquerades TV traffic going out the WAN interface;
#                · logs every blocked packet with a greppable prefix.
#
# DNS-over-HTTPS is blocked implicitly: the TV can only reach IPs that
# were resolved from allowlisted domains (or statically allowlisted), so
# it cannot contact any DoH server unless you explicitly allow it.
#
# Checking the logs
# ─────────────────
#   # Blocked DNS queries  (dnsmasq answered with 0.0.0.0 / ::)
#   journalctl -u tv-filter-dnsmasq | grep 'is 0.0.0.0\|is ::'
#
#   # Allowed DNS queries  (forwarded and answered by upstream)
#   journalctl -u tv-filter-dnsmasq | grep ' reply '
#
#   # Blocked IP connections  (firewall)
#   journalctl -k | grep TV_BLOCKED_IP
#
#   # Blocked external DNS attempts  (should be rare — most get redirected)
#   journalctl -k | grep TV_BLOCKED_EXT_DNS
#
#   # Blocked IPv6 attempts
#   journalctl -k | grep TV_BLOCKED_v6
#
#
# Example usage in your configuration.nix
# ────────────────────────────────────────
#   imports = [ ./tv-filter.nix ];
#
#   services.tvFilter = {
#     enable = true;
#     tvInterface  = "eth0";
#     wanInterface = "wlan0";
#
#     allowedDomains = [
#       # Spotify
#       "spotify.com"
#       "spotify.net"           # Spotify CDN
#       "spotifycdn.com"
#       "scdn.co"
#       "audio-ak-spotify-com.akamaized.net"
#
#       # YouTube
#       "youtube.com"
#       "googlevideo.com"       # YouTube video streams
#       "ytimg.com"
#       "ggpht.com"
#       "googleapis.com"
#       "gstatic.com"
#       "google.com"            # accounts / OAuth
#
#       # NTP (some TVs resolve NTP servers by name)
#       "pool.ntp.org"
#     ];
#
#     allowedIPv4s = [
#       # Google public DNS (if your TV insists on health-checking it)
#       # "8.8.8.8"
#       # "8.8.4.4"
#     ];
#   };

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tvFilter;

  # ── dnsmasq configuration file ──────────────────────────────────────

  dnsmasqConf = pkgs.writeText "tv-filter-dnsmasq.conf" (concatStringsSep "\n" ([
    # ── interface ──
    "interface=${cfg.tvInterface}"
    "bind-interfaces"
    "except-interface=lo"
    "listen-address=${cfg.tvAddress}"

    # ── DHCP ──
    "dhcp-range=${cfg.dhcpRange}"
    "dhcp-option=option:router,${cfg.tvAddress}"
    "dhcp-option=option:dns-server,${cfg.tvAddress}"
    "dhcp-leasefile=/var/lib/tv-filter-dnsmasq/leases"

    # ── general ──
    "no-resolv"
    "no-poll"
    "bogus-priv"
    "domain-needed"
    "pid-file="

    # ── block everything by default ──
    "address=/#/0.0.0.0"
    "address=/#/::"

    # ── logging (goes to journal via stderr) ──
    "log-queries=extra"
    "log-facility=-"
  ]

  # ── per-domain allow rules ──
  ++ concatMap (domain: [
    "server=/${domain}/${cfg.upstreamDNS}"
    "nftset=/${domain}/4#inet#tv_filter#allowed_dns_ips"
  ]) cfg.allowedDomains));

  # ── nftables ruleset ────────────────────────────────────────────────

  staticIPElements = concatStringsSep ", " cfg.allowedIPv4s;

  nftRuleset = pkgs.writeText "tv-filter.nft" ''
    table inet tv_filter {

      # Dynamically populated by dnsmasq when it resolves an allowlisted
      # domain.  Entries expire after the configured timeout; they are
      # re-added on the next DNS lookup.
      set allowed_dns_ips {
        type ipv4_addr
        flags timeout
        timeout ${cfg.nftsetTimeout}
      }

      ${optionalString (cfg.allowedIPv4s != []) ''
      # Static allowlist — IPs/ranges that are always reachable.
      set allowed_static_ips {
        type ipv4_addr
        flags interval
        elements = { ${staticIPElements} }
      }
      ''}

      chain forward {
        type filter hook forward priority filter + 10; policy accept;

        # ── only touch traffic coming FROM the TV ──
        iifname != "${cfg.tvInterface}" accept

        # Let return traffic through for established connections.
        ct state established,related accept

        # ── IPv6: drop everything ──
        meta nfproto ipv6 log prefix "TV_BLOCKED_v6: " counter drop

        # ── prevent the TV from bypassing local DNS ──
        # (redirected in the prerouting chain — this is a safety net
        #  in case something slips through, e.g. a port we missed)
        tcp dport 53 log prefix "TV_BLOCKED_EXT_DNS: " counter drop
        udp dport 53 log prefix "TV_BLOCKED_EXT_DNS: " counter drop

        # ── allow traffic to dynamically resolved IPs ──
        ip daddr @allowed_dns_ips accept

        ${optionalString (cfg.allowedIPv4s != []) ''
        # ── allow traffic to statically allowlisted IPs ──
        ip daddr @allowed_static_ips accept
        ''}

        # ── drop everything else ──
        log prefix "TV_BLOCKED_IP: " counter drop
      }

      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr ${cfg.tvSubnet} oifname "${cfg.wanInterface}" masquerade
      }

      # Redirect any DNS the TV sends to external servers back to our
      # local dnsmasq, so filtering still applies even when the TV has
      # hardcoded DNS (e.g. 8.8.8.8).
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        iifname "${cfg.tvInterface}" ip daddr != ${cfg.tvAddress} udp dport 53 counter dnat to ${cfg.tvAddress}:53
        iifname "${cfg.tvInterface}" ip daddr != ${cfg.tvAddress} tcp dport 53 counter dnat to ${cfg.tvAddress}:53
      }
    }
  '';

in {

  # ═══════════════════════════════════════════════════════════════════
  # Options
  # ═══════════════════════════════════════════════════════════════════

  options.services.tvFilter = {

    enable = mkEnableOption "smart TV network filter";

    # ── network topology ──

    tvInterface = mkOption {
      type        = types.str;
      default     = "eth0";
      description = "Network interface connected to the TV.";
    };

    wanInterface = mkOption {
      type        = types.str;
      default     = "wlan0";
      description = "Internet-facing (upstream) network interface.";
    };

    tvAddress = mkOption {
      type        = types.str;
      default     = "10.10.10.1";
      description = "IPv4 address of the Pi on the TV-facing interface.";
    };

    tvPrefixLength = mkOption {
      type        = types.int;
      default     = 24;
      description = "Prefix length for the TV-facing subnet.";
    };

    tvSubnet = mkOption {
      type        = types.str;
      default     = "10.10.10.0/24";
      description = "TV-facing subnet in CIDR notation (used for NAT).";
    };

    dhcpRange = mkOption {
      type        = types.str;
      default     = "10.10.10.100,10.10.10.200,255.255.255.0,24h";
      description = "DHCP range for dnsmasq (start,end,netmask,lease-time).";
    };

    # ── DNS ──

    upstreamDNS = mkOption {
      type        = types.str;
      default     = "127.0.0.53";
      description = ''
        Upstream DNS server for resolving allowlisted domains.
        Defaults to 127.0.0.53 (systemd-resolved stub listener),
        which forwards to whatever the system's network provides.
        Set to e.g. "1.1.1.1" to override.
      '';
    };

    # ── allowlists ──

    allowedDomains = mkOption {
      type        = types.listOf types.str;
      default     = [];
      example     = [ "spotify.com" "youtube.com" "googlevideo.com" ];
      description = ''
        Domains the TV may resolve.  Subdomains are included automatically
        (e.g. "spotify.com" also allows "api.spotify.com").
        Resolved A-record IPs are pushed into an nftables set so the
        firewall allows connections to them.
      '';
    };

    allowedIPv4s = mkOption {
      type        = types.listOf types.str;
      default     = [];
      example     = [ "35.186.224.0/24" ];
      description = ''
        Static IPv4 addresses or CIDR ranges the TV may always connect to,
        regardless of DNS.  Use this for services the TV contacts by IP.
      '';
    };

    # ── tuning ──

    nftsetTimeout = mkOption {
      type        = types.str;
      default     = "1h";
      description = ''
        How long a dynamically resolved IP stays in the firewall allowlist
        before it expires.  It is re-added on the next DNS lookup.
        Established connections survive expiry (via conntrack).
      '';
    };

    dnsmasqPackage = mkOption {
      type        = types.package;
      default     = pkgs.dnsmasq;
      defaultText = literalExpression "pkgs.dnsmasq";
      description = ''
        dnsmasq package to use.  Must be built with nftset support
        (requires libnftnl; the default nixpkgs build includes this).
      '';
    };
  };

  # ═══════════════════════════════════════════════════════════════════
  # Implementation
  # ═══════════════════════════════════════════════════════════════════

  config = mkIf cfg.enable {

    # ── kernel parameters ──

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.${cfg.tvInterface}.disable_ipv6" = 1;
      "net.ipv6.conf.${cfg.tvInterface}.accept_ra"    = 0;
    };

    # ── TV-facing interface: static IPv4, no IPv6 ──

    networking.interfaces.${cfg.tvInterface} = {
      ipv4.addresses = [{
        address      = cfg.tvAddress;
        prefixLength = cfg.tvPrefixLength;
      }];
      ipv6.addresses = mkForce [];
    };

    # ── let DHCP and DNS through the system firewall on the TV iface ──

    networking.firewall.interfaces.${cfg.tvInterface} = {
      allowedUDPPorts = [ 53 67 ];
      allowedTCPPorts = [ 53 ];
    };

    # If the NixOS firewall filters FORWARD traffic, let TV traffic
    # through — our tv_filter table handles the actual filtering.
    networking.firewall.extraForwardRules = ''
      iifname "${cfg.tvInterface}" accept
    '';

    # ── dnsmasq: dedicated instance for DNS + DHCP ──

    systemd.services.tv-filter-dnsmasq = {
      description = "TV Filter — DNS/DHCP (dnsmasq)";
      documentation = [ "man:dnsmasq(8)" ];

      after    = [ "network.target" "tv-filter-firewall.service" ];
      requires = [ "tv-filter-firewall.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.dnsmasqPackage}/bin/dnsmasq --keep-in-foreground --conf-file=${dnsmasqConf}";
        Restart    = "on-failure";
        RestartSec = 5;

        # Run as an unprivileged dynamic user with only the
        # capabilities dnsmasq needs.
        DynamicUser          = true;
        StateDirectory       = "tv-filter-dnsmasq";
        AmbientCapabilities  = [ "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" "CAP_NET_ADMIN" ];

        # Hardening
        ProtectSystem  = "strict";
        ProtectHome    = true;
        PrivateTmp     = true;
        NoNewPrivileges = true;
      };
    };

    # ── nftables: self-contained filtering table ──

    systemd.services.tv-filter-firewall = {
      description = "TV Filter — Firewall (nftables)";

      before   = [ "network.target" ];
      after    = [ "network-pre.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type             = "oneshot";
        RemainAfterExit  = true;
        ExecStart        = "${pkgs.nftables}/bin/nft -f ${nftRuleset}";
        ExecStop         = "${pkgs.nftables}/bin/nft delete table inet tv_filter";
        ExecReload       = [
          "${pkgs.nftables}/bin/nft delete table inet tv_filter"
          "${pkgs.nftables}/bin/nft -f ${nftRuleset}"
        ];
      };
    };
  };
}
