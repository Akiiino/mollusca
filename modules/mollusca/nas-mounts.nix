{
  config,
  lib,
  ...
}:
let
  cfg = config.mollusca.nasMounts;

  mountOpts = lib.types.submodule {
    options = {
      share = lib.mkOption {
        type = lib.types.str;
        example = "MyCloudEX2Ultra.local:/nfs/Media";
        description = "NFS export to mount, in `host:/path` form.";
      };
      hard = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If true, use the NFS `hard` option (block forever if the NAS is
          unavailable). If false, use `soft` so that calls fail rather than
          hang the machine.
        '';
      };
    };
  };

  mkOptions = m: [
    "x-systemd.automount" # Mount on first access
    "noauto" # Don't mount at boot
    "x-systemd.idle-timeout=600" # Unmount after 10min idle
    "nfsvers=3"
    (if m.hard then "hard" else "soft")
    "timeo=50" # 5 second timeout
    "retrans=4" # 4 retries before giving up
    "_netdev" # Wait for network
  ];
in
{
  options.mollusca.nasMounts = lib.mkOption {
    type = lib.types.attrsOf mountOpts;
    default = { };
    example = lib.literalExpression ''
      {
        "/mnt/media" = {
          share = "MyCloudEX2Ultra.local:/nfs/Media";
        };
      }
    '';
    description = ''
      NFS mounts for the household NAS, with consistent options across
      machines. Mounts are auto-mounted on access and unmounted after
      10 minutes idle.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    boot.supportedFilesystems = [ "nfs" ];
    fileSystems = lib.mapAttrs (_: m: {
      device = m.share;
      fsType = "nfs";
      options = mkOptions m;
    }) cfg;
  };
}
