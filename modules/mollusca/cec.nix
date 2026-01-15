{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.mollusca.cec;
in
{
  options.mollusca.cec = {
    enable = lib.mkEnableOption "HDMI-CEC support";
    connector = lib.mkOption {
      type = lib.types.str;
      example = "card1-DP-2";
      description = "DRM connector name (from /sys/class/drm/) for the HDMI output";
    };
    osdName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName or null;
      description = "Name shown in TV menus (max 14 ASCII characters)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.v4l-utils ];

    services.udev.extraRules = ''
      SUBSYSTEM=="cec", KERNEL=="cec0", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="cec-configure.service"
    '';

    # Remap CEC remote keys to standard keyboard keys
    # Default kernel mappings (rc-cec.c) use media keys that apps don't recognize
    # Format: KEYBOARD_KEY_<scancode>=<keyname>
    # See: https://github.com/torvalds/linux/blob/master/drivers/media/rc/keymaps/rc-cec.c
    services.udev.extraHwdb = ''
      evdev:name:DP-*:*
      evdev:name:HDMI-*:*
      evdev:name:RC for *:*
        KEYBOARD_KEY_00=enter
        KEYBOARD_KEY_0d=esc
        KEYBOARD_KEY_09=homepage
        KEYBOARD_KEY_0a=setup
        KEYBOARD_KEY_0b=menu
        KEYBOARD_KEY_10=menu
        KEYBOARD_KEY_11=compose
        KEYBOARD_KEY_20=0
        KEYBOARD_KEY_21=1
        KEYBOARD_KEY_22=2
        KEYBOARD_KEY_23=3
        KEYBOARD_KEY_24=4
        KEYBOARD_KEY_25=5
        KEYBOARD_KEY_26=6
        KEYBOARD_KEY_27=7
        KEYBOARD_KEY_28=8
        KEYBOARD_KEY_29=9
        KEYBOARD_KEY_71=f1
        KEYBOARD_KEY_72=f2
        KEYBOARD_KEY_73=f3
        KEYBOARD_KEY_74=f4
    '';

    systemd.services.cec-configure = {
      description = "Configure HDMI-CEC adapter";
      bindsTo = [ "dev-cec0.device" ];
      serviceConfig = {
        Type = "exec";
        ExecStart =
          "${pkgs.v4l-utils}/bin/cec-ctl --device=0 --playback --phys-addr-from-edid-poll=/sys/class/drm/${cfg.connector}/edid"
          + (lib.optionalString (
            !(builtins.isNull cfg.osdName)
          ) " --osd-name=${lib.escapeShellArg cfg.osdName}");
      };
    };
  };
}
