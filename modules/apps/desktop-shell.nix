{ pkgs, ... }:
let
  swaylockPackage = pkgs.swaylock-effects;
in
{
  home.packages = with pkgs; [
    pavucontrol
    networkmanagerapplet
    thunar
    kdePackages.ark
  ];

  programs = {
    walker = {
      enable = true;
      runAsService = true;
    };

    swaylock = {
      enable = true;
      package = swaylockPackage;
      settings = {
        clock = true;
        timestr = "%H:%M";
        datestr = "%A, %B %e";
        indicator = true;
        indicator-radius = 120;
        indicator-thickness = 10;
        screenshots = true;
        ignore-empty-password = true;
        show-failed-attempts = true;
        effect-blur = "10x6";
      };
    };
  };

  services = {
    swayosd = {
      enable = true;
      topMargin = 0.75;
    };
    blueman-applet.enable = true;
    swaync.enable = true;
    poweralertd = {
      enable = true;
      extraArgs = [
        "-s"
        "-i"
        "line-power"
      ];
    };
    playerctld.enable = true;

    # USB automount
    udiskie = {
      enable = true;
      tray = "auto";
    };

    # TODO: this works, but maybe it should use proper types instead of the
    # ad-hoc schedule below. Maybe someone already made a module I can add to my
    # flake?
    swayidle =
      let
        onBattery = pkgs.writeShellScript "on-battery" ''
          for f in /sys/class/power_supply/A*/online; do
            [ -r "$f" ] && [ "$(cat "$f")" = "0" ] && exit 0
          done
          exit 1
        '';

        actions = {
          dim = {
            run = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
            resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          };
          lock.run = "${pkgs.systemd}/bin/loginctl lock-session";
          displayOff.run = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          suspend.run = "${pkgs.systemd}/bin/systemctl suspend";
        };

        schedule = [
          {
            minutes = 10;
            battery = "lock";
            ac = "lock";
          }
          {
            minutes = 11;
            battery = "displayOff";
            ac = null;
          }
          {
            minutes = 15;
            battery = "suspend";
            ac = "displayOff";
          }
        ];

        mkTimeout =
          {
            minutes,
            battery,
            ac,
          }:
          let
            b = if battery == null then null else actions.${battery};
            a = if ac == null then null else actions.${ac};
            command =
              if b != null && a != null then
                (if b.run == a.run then b.run else "if ${onBattery}; then ${b.run}; else ${a.run}; fi")
              else if b != null then
                "if ${onBattery}; then ${b.run}; fi"
              else
                "if ! ${onBattery}; then ${a.run}; fi";
            resume =
              if b != null && b ? resume then
                b.resume
              else if a != null && a ? resume then
                a.resume
              else
                null;
          in
          {
            timeout = minutes * 60;
            inherit command;
          }
          // (if resume == null then { } else { resumeCommand = resume; });
      in
      {
        enable = true;
        events = [
          {
            event = "before-sleep";
            command = "${swaylockPackage}/bin/swaylock -f";
          }
          {
            event = "lock";
            command = " ${pkgs.brightnessctl}/bin/brightnessctl -r; ${swaylockPackage}/bin/swaylock -f; ${pkgs.niri}/bin/niri msg action power-off-monitors";
          }
        ];
        timeouts = map mkTimeout schedule;
      };

    wl-clip-persist = {
      enable = true;
      clipboardType = "regular";
      extraOptions = [
        "--all-mime-type-regex"
        "^(?!x-kde-passwordManagerHint).+"
      ];
    };
  };
}
