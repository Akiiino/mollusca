{ pkgs, lib, ... }:
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
    walker = {
      enable = true;
      package = pkgs.mollusca.walker;
      systemd.enable = true;
      enableElephantIntegration = true;
      settings.providers = {
        default = [
          "desktopapplications"
          "calc"
        ];
        empty = [ "desktopapplications" ];
        prefixes = [
          {
            prefix = ">";
            provider = "niriactions";
          }
          {
            prefix = "%";
            provider = "nirisessions";
          }
          {
            prefix = "@";
            provider = "unicode";
          }
        ];
      };
    };
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
        events = {
          "before-sleep" = "${swaylockPackage}/bin/swaylock -f";
          "lock" = "${swaylockPackage}/bin/swaylock -f; ${pkgs.niri}/bin/niri msg action power-off-monitors";
        };
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

  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant - Data provider for application launchers";
      # By default elephant tries to start before graphics and dies.
      # TODO: suggest upstream?
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = lib.getExe pkgs.mollusca.elephant;
      Restart = "on-failure";
    };
  };
}
