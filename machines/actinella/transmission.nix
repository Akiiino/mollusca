# transmission.nix — Transmission confined to ProtonVPN with NAT-PMP port forwarding.
#
# Import this file in your system configuration:
#   imports = [ ./transmission.nix ];
#
# Prerequisites:
#   - The vpn-confinement module is loaded (via flake nixosModules.default)
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

{ self, pkgs, lib, config, ... }:

let
  natpmpGateway = "10.2.0.1";

  nsAddr = "192.168.15.1";
  rpcPort = 9091;
in {

  # ── VPN namespace ───────────────────────────────────────────────────

  age.secrets.proton-wireguard.file = "${self}/secrets/proton-wireguard.age";
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.age.secrets.proton-wireguard.path;
    accessibleFrom = [ "192.168.1.0/24" ];
    namespaceAddress = nsAddr;

    portMappings = [
      { from = rpcPort; to = rpcPort; protocol = "tcp"; }
    ];
  };

  # ── Transmission ────────────────────────────────────────────────────

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      # Bind the WebUI to the namespace's veth address.
      rpc-bind-address = nsAddr;

      bind-address-ipv6 = "";

      # Allow LAN clients to access the WebUI.
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1,${nsAddr},192.168.15.*";

      # Disable Transmission's built-in port forwarding — the sidecar
      # handles this via NAT-PMP directly with ProtonVPN.
      port-forwarding-enabled = false;

      # Start with a placeholder peer port. The sidecar will update
      # this at runtime once it gets the NAT-PMP assignment.
      peer-port = 51413;

      download-dir = "/mnt/media/Staging/";
    };
  };

  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  # Transmission stores data under /var/lib/transmission — the default
  # ProtectHome=true is fine since that's not under /home. But
  # ProtectSystem=strict makes / read-only, and Transmission needs to
  # write to its state and download directories. NixOS's transmission
  # module already handles this via ReadWritePaths, but if you store
  # downloads elsewhere, add the path here:
  #
  systemd.services.transmission.serviceConfig = {
    BindPaths = [ "/mnt/media" ];
    ReadWritePaths = [ "/var/lib/transmission" ];
  };
  # ── NAT-PMP sidecar ────────────────────────────────────────────────
  #
  # Runs inside the same VPN namespace. Every 45 seconds it:
  #   1. Requests a port mapping from ProtonVPN via NAT-PMP
  #   2. Opens that port in the namespace's nftables firewall
  #   3. Tells Transmission to use it for incoming peer connections

  systemd.services.transmission-natpmp = {
    description = "ProtonVPN NAT-PMP port forwarding for Transmission";
    after = [ "transmission.service" ];
    requires = [ "transmission.service" ];
    wantedBy = [ "multi-user.target" ];

    vpnConfinement = {
      enable = true;
      vpnNamespace = "wg";
    };

    # The sidecar needs CAP_NET_ADMIN to modify nftables rules.
    # Override some hardening defaults that would interfere.
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = 10;

      # nft needs netlink access (CAP_NET_ADMIN). The hardening
      # defaults from vpnConfinement are fine — nft uses netlink
      # sockets, not sysfs or procfs.
    };

    path = with pkgs; [
      libnatpmp      # natpmpc
      nftables       #5 nft
      transmission_4 # transmission-re5mote
      gawk           # awk
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
}
