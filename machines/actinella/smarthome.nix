{ config, pkgs, lib, self, ... }:
let
  mosquitto-port = 1883;
  zigbee2mqtt-port = 8085;
  openhab-port = 8080;

  podman = config.virtualisation.podman.package;

  openhab-image = "docker.io/openhab/openhab:5.1.4@sha256:d583a280a8a8cdbff5bcebe5bd7d04a7839769350a7e54f600b4aaa26162392f";
in
{
  # Mosquitto: per-service auth, anonymous denied.
  #
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "127.0.0.1";
        port = mosquitto-port;
        users = {
          zigbee2mqtt = {
            hashedPasswordFile = config.age.secrets.mosquitto-zigbee2mqtt-password.path;
            acl = [ "readwrite #" ];
          };
          openhab = {
            hashedPasswordFile = config.age.secrets.mosquitto-openhab-password.path;
            acl = [ "readwrite #" ];
          };
        };
      }
    ];
  };

  age.secrets.zigbee2mqtt-secrets = {
    file = "${self}/secrets/zigbee2mqtt.age";
    owner = "zigbee2mqtt";
    group = "zigbee2mqtt";
    mode = "0400";
  };

  age.secrets.mosquitto-zigbee2mqtt-password.file =
    "${self}/secrets/mosquitto-zigbee2mqtt-password.age";
  age.secrets.mosquitto-openhab-password.file =
    "${self}/secrets/mosquitto-openhab-password.age";

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      serial = {
        port = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
        adapter = "ember";
        baudrate = 115200;
        serial.rtscts = true;
      };

      mqtt = {
        server = "mqtt://127.0.0.1:${toString mosquitto-port}";
        user = "!secrets.yaml mqtt_user";
        password = "!secrets.yaml mqtt_password";
      };

      frontend = {
        host = "127.0.0.1";
        port = zigbee2mqtt-port;
      };

      advanced = {
        network_key = "!secrets.yaml network_key";
        pan_id = 26632;
        ext_pan_id = [167 205 123 235 244 185 208 31];
      };
    };
  };

  systemd.services.zigbee2mqtt.preStart = lib.mkAfter ''
    install -m 0400 -o zigbee2mqtt -g zigbee2mqtt \
      ${config.age.secrets.zigbee2mqtt-secrets.path} \
      /var/lib/zigbee2mqtt/secrets.yaml
  '';

  # ── OpenHAB (rootless podman) ───────────────────────────────────────
  #
  # The upstream openhab/openhab image is designed to start as in-container
  # root: the entrypoint does timezone setup, applies the Java unlimited-
  # crypto policy, renames uid/gid 9001 to "openhab", chowns mounts, then
  # demotes to uid 9001 before launching the JVM. Forcing --user=9001:9001
  # to skip that phase is explicitly unsupported (openhab-docker#353).
  #
  # We run podman *rootless* under a dedicated unprivileged host user
  # instead (uid auto-assigned by NixOS). The container's internal uid 0
  # maps to that user via subuid/subgid namespacing — the entrypoint gets
  # the in-container privileges it needs, but at no point does anything
  # in the container have a path to host root.
  #
  # State lives in plain bind mounts under /var/lib/openhab/{conf,userdata,
  # addons}. Because of subuid namespacing the files appear on the host as
  # owned by a high subuid (~209000) rather than uid 9001, but the paths
  # themselves are canonical and `sudo` can read them directly. ExecStartPre
  # uses `podman unshare chown` to assign the right namespaced ownership
  # idempotently on each start.

  virtualisation.podman.enable = true;

  # Defaults appropriate for rootless podman without a user systemd session:
  # cgroupfs cgroup driver (podman would otherwise warn and fall back), and
  # file-based event logging (the default `journald` driver tries to talk to
  # the user's systemd bus, which doesn't exist here).
  virtualisation.containers.containersConf.settings.engine = {
    cgroup_manager = "cgroupfs";
    events_logger = "file";
  };

  users.groups.openhab = { };
  users.users.openhab = {
    isSystemUser = true;
    group = "openhab";
    home = "/var/lib/openhab";
    createHome = true;
    homeMode = "0750";
    subUidRanges = [ { startUid = 200000; count = 65536; } ];
    subGidRanges = [ { startGid = 200000; count = 65536; } ];
  };

  systemd.services.openhab = {
    description = "OpenHAB (rootless podman)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "mosquitto.service"
    ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      # Type=exec is the right fit for a system unit running rootless podman
      # *without* a user systemd session. The fancier Type=notify +
      # --sdnotify=conmon pattern needs the user's systemd bus to coordinate
      # with conmon, which we don't have here on purpose.
      Type = "exec";
      User = "openhab";
      Group = "openhab";
      WorkingDirectory = "/var/lib/openhab";
      # /run/openhab on tmpfs, owned by the openhab user. Replaces the need
      # for /run/user/<uid>, so we don't depend on user@<uid>.service and
      # the uid can be auto-assigned. Preserve across Restart= cycles so
      # podman's runtime state isn't lost between attempts.
      RuntimeDirectory = "openhab";
      RuntimeDirectoryMode = "0700";
      RuntimeDirectoryPreserve = "yes";
      Environment = [
        "XDG_RUNTIME_DIR=/run/openhab"
        "HOME=/var/lib/openhab"
      ];
      ExecStartPre = [
        # Create state dirs (idempotent; openhab owns /var/lib/openhab).
        "${pkgs.coreutils}/bin/mkdir -p /var/lib/openhab/conf /var/lib/openhab/userdata /var/lib/openhab/addons"
        # Map in-container uid 9001 → corresponding host subuid. Idempotent.
        "${podman}/bin/podman unshare ${pkgs.coreutils}/bin/chown -R 9001:9001 /var/lib/openhab/conf /var/lib/openhab/userdata /var/lib/openhab/addons"
        # Pre-pull so the main start phase isn't dominated by image fetch
        # (no-op once cached, since the image is pinned by digest).
        "${podman}/bin/podman pull ${openhab-image}"
        # `-` prefix: ignore failure (no container to remove on first start).
        "-${podman}/bin/podman rm -f openhab"
      ];
      # `--rm` is intentionally absent: we rely on the ExecStartPre `podman
      # rm -f` for cleanup. Letting --rm tear down the container immediately
      # on exit races with conmon writing the exit file, especially without
      # a user systemd manager around to coordinate.
      # --no-healthcheck disables the container's HEALTHCHECK directive. Podman
      # would otherwise try to register a systemd transient timer for it via
      # the user systemd bus (absent here) and fail at startup. We don't
      # consume container healthcheck status — systemd Restart=on-failure
      # handles crash recovery directly.
      #
      # Networking: we deliberately don't use --network=host. Instead the
      # container runs in its own namespace (rootless podman default, pasta
      # backend) and OH's HTTP port is published only on 127.0.0.1 of the
      # host. nginx (from mollusca.lanServices) proxies to it; nothing else
      # on LAN/Tailscale can hit OH directly. --add-host gives the container
      # a stable name to reach the host (for the Mosquitto broker on the
      # host's 127.0.0.1) regardless of which rootless network backend is
      # in use.
      ExecStart = pkgs.writeShellScript "openhab-run" ''
        exec ${podman}/bin/podman run \
          --replace --name=openhab \
          --no-healthcheck \
          --publish=127.0.0.1:${toString openhab-port}:${toString openhab-port} \
          --add-host=host.containers.internal:host-gateway \
          --env=CRYPTO_POLICY=unlimited \
          --env=TZ=${config.time.timeZone} \
          --env=OPENHAB_HTTP_PORT=${toString openhab-port} \
          --volume=/var/lib/openhab/conf:/openhab/conf \
          --volume=/var/lib/openhab/userdata:/openhab/userdata \
          --volume=/var/lib/openhab/addons:/openhab/addons \
          ${openhab-image}
      '';
      ExecStop = "${podman}/bin/podman stop -t 30 openhab";
      Restart = "on-failure";
      RestartSec = "10s";
      # Forward SIGTERM only to the podman process (MainPID); it propagates
      # to the container itself, allowing OH to shut down cleanly.
      KillMode = "mixed";
      # First-start image pull is ~500 MB; default 90s isn't enough.
      TimeoutStartSec = 600;
      TimeoutStopSec = 60;
    };
  };

  mollusca.lanServices.services = {
    "oh.akiiino.me" = {
      proxyPass = "http://127.0.0.1:${toString openhab-port}";
      websocket = true;
    };
    "z2m.akiiino.me" = {
      proxyPass = "http://127.0.0.1:${toString zigbee2mqtt-port}";
      websocket = true;
    };
  };
}
