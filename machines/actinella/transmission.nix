# transmission.nix — Transmission confined to ProtonVPN with NAT-PMP port forwarding.
#
# Import this file in your system configuration:
#   imports = [ ./transmission.nix ];
#
# Prerequisites:
#   - The WG-Jail module is loaded (inputs.WG-jail.nixosModules.default),
#     which provides the vpnNamespaces options used below.
#   - A ProtonVPN WireGuard config file at the path below, from a P2P server
#     with "NAT-PMP (Port Forwarding) = on"
#
# How it works:
#   1. A VPN namespace "wg" is created with a WireGuard tunnel to ProtonVPN.
#   2. Transmission runs inside the namespace — all its traffic goes through
#      the VPN. If the tunnel goes down, traffic is dropped (kill switch).
#   3. A sidecar service (also inside the namespace) uses NAT-PMP to request
#      a forwarded port from ProtonVPN, opens it in the namespace firewall,
#      and tells Transmission to use it for incoming peer connections.
#   4. Transmission's WebUI is accessible from the LAN via port mapping.
#
# The LAN reaches Transmission's WebUI like this:
#
#   LAN client (192.168.1.x)
#     → your-host:9091               (host's LAN IP)
#     → DNAT to 192.168.15.1:9091    (namespace veth address)
#     → Transmission inside namespace
#
#   192.168.15.1 is NOT your machine's LAN IP. It's the address of the
#   virtual interface (veth) inside the VPN namespace. Transmission binds
#   to it because it's the only routable non-VPN interface it can see.
#   The DNAT port mapping makes this transparent to LAN clients.
#
# Download & hardlink workflow:
#   Transmission downloads to /mnt/media/Seeding/ (its private directory).
#   When a torrent completes, a script hardlinks every file into
#   /mnt/media/Staging/, preserving the directory structure.
#
#   You work with /mnt/media/Staging/ — rename, reorganise, delete files
#   at will. Transmission keeps seeding from /mnt/media/Seeding/ undisturbed.
#   Since hardlinks share data blocks, there's no extra disk space used.
#
#   When you remove a torrent from Transmission (with "delete local data"),
#   the Seeding copy is removed and the disk blocks are freed only if no
#   hardlinks remain — i.e. only once you've also cleaned up Staging.

{
  self,
  pkgs,
  lib,
  config,
  minor-secrets,
  ...
}:

let
  natpmpGateway = "10.2.0.1";

  nsAddr = "192.168.15.1";
  rpcPort = 9091;

  # Where Transmission downloads and seeds from (don't touch these files).
  seedDir = "/mnt/media/Seeding";

  # Where hardlinks appear for you to organise.
  stagingDir = "/mnt/media/Staging";

  # Script that Transmission calls when a torrent finishes downloading.
  # Transmission sets these environment variables:
  #   TR_TORRENT_DIR  — the directory the torrent was downloaded to
  #   TR_TORRENT_NAME — the name of the torrent (file or top-level dir)
  hardlinkScript = pkgs.writeShellScript "transmission-hardlink" ''
    set -euo pipefail
    cp -al "$TR_TORRENT_DIR/$TR_TORRENT_NAME" "${stagingDir}/$TR_TORRENT_NAME"
  '';

  settingsJson = "/var/lib/transmission/.config/transmission-daemon/settings.json";

  # Runs as an ExecStartPre of transmission, ordered *after* the nixpkgs module's
  # own prestart (which regenerates settings.json from the static config). It
  # primes settings.json with the real NAT-PMP forwarded port before the daemon
  # starts, so the very first tracker announce advertises the correct port
  # instead of the 51413 placeholder.
  #
  # This needs only the VPN namespace (for natpmpc), not Transmission's RPC — so
  # unlike the sidecar it can run before the daemon. It deliberately does NOT
  # touch the firewall (that needs CAP_NET_ADMIN); the sidecar opens the port a
  # few seconds later, and inbound peers retry. If NAT-PMP is unavailable it
  # leaves the placeholder and exits 0, so a slow tunnel never blocks startup —
  # the sidecar then corrects the port over RPC exactly as before.
  peerPortPrestart = pkgs.writeShellScript "transmission-peer-port-prestart" ''
    set -uo pipefail

    natpmpc='${pkgs.libnatpmp}/bin/natpmpc'
    jq='${pkgs.jq}/bin/jq'
    awk='${pkgs.gawk}/bin/awk'

    get_port() {
      "$natpmpc" -a 1 0 udp 60 -g ${natpmpGateway} 2>/dev/null \
        | "$awk" '/Mapped public port/ { print $4 }'
    }

    port=""
    for _ in 1 2 3 4 5; do
      port=$(get_port)
      [ -n "$port" ] && break
      sleep 3
    done

    if [ -z "$port" ]; then
      echo "prestart: NAT-PMP unavailable, leaving placeholder; sidecar will update" >&2
      exit 0
    fi

    # Refresh the TCP mapping too (same public port) so inbound works once the
    # sidecar opens the firewall.
    "$natpmpc" -a 1 0 tcp 60 -g ${natpmpGateway} > /dev/null 2>&1 || true

    tmp="${settingsJson}.tmp"
    if "$jq" --arg p "$port" '."peer-port" = ($p | tonumber)' "${settingsJson}" > "$tmp"; then
      mv "$tmp" "${settingsJson}"
      echo "prestart: peer-port set to $port"
    else
      rm -f "$tmp"
      echo "prestart: failed to update settings.json, leaving placeholder" >&2
    fi
  '';
in
{

  # ── VPN namespace ───────────────────────────────────────────────────

  age.secrets.proton-wireguard.file = "${self}/secrets/proton-wireguard.age";
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.age.secrets.proton-wireguard.path;
    accessibleFrom = [ "192.168.1.0/24" ];
    namespaceAddress = nsAddr;

    portMappings = [
      {
        from = rpcPort;
        to = rpcPort;
        protocol = "tcp";
      }
    ];
  };

  # ── Transmission ────────────────────────────────────────────────────

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      # Bind the WebUI to the namespace's veth address.
      rpc-bind-address = nsAddr;

      # Allow LAN clients to access the WebUI.
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1,${nsAddr},192.168.15.*";

      bind-address-ipv6 = "::";

      # Disable Transmission's built-in port forwarding — the sidecar
      # handles this via NAT-PMP directly with ProtonVPN.
      port-forwarding-enabled = false;

      # Placeholder peer port. An ExecStartPre primes settings.json with the
      # real NAT-PMP port before the daemon starts (so the first announce is
      # correct); the sidecar then keeps it updated at runtime.
      peer-port = 51413;

      # Download into the seeding directory. Transmission owns this —
      # don't rename or move files here, or seeding will break.
      download-dir = seedDir;

      # When a torrent finishes, run the hardlink script to create
      # links in the staging directory.
      script-torrent-done-enabled = true;
      script-torrent-done-filename = "${hardlinkScript}";
    };
  };

  systemd.services = {
    transmission = {
      vpnConfinement = {
        enable = true;
        vpnNamespace = "wg";
      };

      # mkForce the whole BindPaths list. The nixpkgs module derives
      # BindPaths from the configured download-dir, which would bind-mount
      # /mnt/media/Seeding on its own. That separate mount breaks the
      # Seeding→Staging hardlinks (links can't span mount points), so we
      # bind the parent /mnt/media instead and keep Seeding and Staging on
      # one filesystem.
      serviceConfig = {
        BindPaths = lib.mkForce [
          "/var/lib/transmission/.config/transmission-daemon"
          "/run"
          "/var/lib/transmission/.incomplete"
          "/mnt/media"
        ];
        ReadWritePaths = [ "/var/lib/transmission" ];

        # Prime settings.json with the real NAT-PMP port before the daemon
        # starts. mkAfter so it runs after the module's own prestart, which
        # regenerates settings.json from the static config. No "+" prefix: it
        # must run as the transmission user (owns settings.json) and inside the
        # VPN namespace (for natpmpc).
        ExecStartPre = lib.mkAfter [ "${peerPortPrestart}" ];
      };
    };

    # ── NAT-PMP sidecar ────────────────────────────────────────────────
    #
    # Runs inside the same VPN namespace. Every 45 seconds it:
    #   1. Requests a port mapping from ProtonVPN via NAT-PMP
    #   2. Opens that port in the namespace's nftables firewall
    #   3. Tells Transmission to use it for incoming peer connections
    transmission-natpmp = {
      description = "ProtonVPN NAT-PMP port forwarding for Transmission";
      after = [ "transmission.service" ];
      requires = [ "transmission.service" ];
      wantedBy = [ "multi-user.target" ];

      vpnConfinement = {
        enable = true;
        vpnNamespace = "wg";
      };

      # Restart on failure so the lease keeps getting renewed. No hardening
      # overrides are needed: nft modifies the namespace's nftables via
      # netlink sockets, which work under the service's default caps.
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
      };

      path = [
        pkgs.libnatpmp # natpmpc
        pkgs.nftables # nft
        config.services.transmission.package # transmission-remote
        pkgs.gawk # awk
      ];

      script = ''
        # The NAT-PMP chain is managed exclusively by this sidecar.
        # Create it on first run; flush and rebuild on each renewal.
        # The jump from the main input chain is idempotent — if it
        # already exists, the add command succeeds silently.
        setup_chain() {
          nft add chain inet vpn-wg natpmp-input 2>/dev/null || true
          # Only add the jump rule if it doesn't already exist.
          # nft add rule always appends, so repeated service restarts
          # would accumulate duplicate jumps.
          if ! nft list chain inet vpn-wg input | grep -q 'jump natpmp-input'; then
            nft add rule inet vpn-wg input jump natpmp-input
          fi
        }

        update_firewall() {
          local port="$1"
          nft flush chain inet vpn-wg natpmp-input
          nft add rule inet vpn-wg natpmp-input iifname "wg0" tcp dport "$port" accept
          nft add rule inet vpn-wg natpmp-input iifname "wg0" udp dport "$port" accept
          echo "firewall: opened port $port on wg0"
        }

        update_transmission() {
          local port="$1"
          # transmission-remote may fail briefly on startup; tolerate it
          if transmission-remote ${nsAddr}:${toString rpcPort} --port "$port" 2>/dev/null; then
            echo "transmission: peer port set to $port"
          else
            echo "transmission: RPC not ready yet, will retry next cycle" >&2
          fi
        }

        setup_chain
        current_port=""

        while true; do
          # Request UDP and TCP port mappings from ProtonVPN.
          # natpmpc -a 1 0 <proto> 60 -g <gateway>
          #   -a 1 0: map local port 1 to server-chosen public port
          #   60: lease lifetime in seconds
          #   -g: NAT-PMP gateway (ProtonVPN's internal IP)
          port=$(
            natpmpc -a 1 0 udp 60 -g ${natpmpGateway} 2>/dev/null \
              | awk '/Mapped public port/ { print $4 }'
          )

          if [[ -z "$port" ]]; then
            echo "error: NAT-PMP request failed, retrying in 15s" >&2
            sleep 15
            continue
          fi

          # Also request TCP (uses the same port)
          natpmpc -a 1 0 tcp 60 -g ${natpmpGateway} > /dev/null 2>&1

          # Only update if the port changed (avoids unnecessary churn)
          if [[ "$port" != "$current_port" ]]; then
            echo "NAT-PMP: assigned port $port (was: ''${current_port:-none})"
            update_firewall "$port"
            update_transmission "$port"
            current_port="$port"
          fi

          # Renew before the 60-second lease expires
          sleep 45
        done
      '';
    };
  };
}
