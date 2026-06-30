{ pkgs, lib, ... }:
let
  swaylockPackage = pkgs.swaylock-effects;
  tomlFormat = pkgs.formats.toml { };

  # elephant reads one TOML file per provider (~/.config/elephant/<provider>.toml),
  # not a single config.toml — so these are written directly via xdg.configFile
  # rather than through services.elephant.settings (which targets config.toml and
  # is inert for this elephant version).
  elephantProviderConfig = {
    desktopapplications = {
      # Focus an already-open window instead of spawning a new instance.
      window_integration = true;
      # Disable most-used (frecency) sorting entirely.
      history = false;
    };
    # Providers reachable via their own keybind are hidden from the Super+D list.
    clipboard.hide_from_providerlist = true;
    windows.hide_from_providerlist = true;
    symbols.hide_from_providerlist = true;
  };
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
      systemd.enable = true;
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
    elephant = {
      enable = true;
      package = pkgs.mollusca.elephant;
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
    # By default elephant tries to start before graphics and dies.
    # TODO: suggest upstream?
    Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    # do not persist clipboard history
    Service.Environment = [ "XDG_CACHE_HOME=%t/elephant-cache" ];
  };

  # elephant reads one TOML file per provider; write the ones we override.
  xdg.configFile = lib.mapAttrs' (
    provider: settings:
    lib.nameValuePair "elephant/${provider}.toml" {
      source = tomlFormat.generate "elephant-${provider}.toml" settings;
    }
  ) elephantProviderConfig;
}
