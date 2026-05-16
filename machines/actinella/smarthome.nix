{ config, pkgs, ... }:
let
  mosquitto-port = 1883;
  zigbee2mqtt-port = 8085;
  openhab-port = 8080;

  javaSecurityOverride = pkgs.writeText "openhab-java.security" ''
    crypto.policy=unlimited
  '';
in
{
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        address = "127.0.0.1";
        port = mosquitto-port;
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      serial = {
        port = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
        adapter = "ember";
        baudrate = 115200;
      };

      mqtt.server = "mqtt://127.0.0.1:${toString mosquitto-port}";

      frontend = {
        host = "127.0.0.1";
        port = zigbee2mqtt-port;
      };
    };
  };

  # UID/GID 9001 is the `openhab` user baked into the upstream image.

  virtualisation = {
    podman.enable = true;
    oci-containers = {
      backend = "podman";
      containers.openhab = {
        image = "docker.io/openhab/openhab:5.1.4@sha256:d583a280a8a8cdbff5bcebe5bd7d04a7839769350a7e54f600b4aaa26162392f";
        environment = {
          CRYPTO_POLICY = "unlimited";
          OPENHAB_HTTP_PORT = toString openhab-port;
          OPENHAB_HTTPS_PORT = "8443";
        };
        volumes = [
          "/var/lib/openhab/conf:/openhab/conf"
          "/var/lib/openhab/userdata:/openhab/userdata"
          "/var/lib/openhab/addons:/openhab/addons"
          "/etc/localtime:/etc/localtime:ro"
          "${javaSecurityOverride}:/etc/openhab/java.security.override:ro"
        ];
        extraOptions = [
          "--network=host"
          "--user=9001:9001"
        ];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/openhab          0755 root root -"
    "d /var/lib/openhab/conf     0755 9001 9001 -"
    "d /var/lib/openhab/userdata 0755 9001 9001 -"
    "d /var/lib/openhab/addons   0755 9001 9001 -"
  ];

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
