{
  pkgs,
  lib,
  theme,
  inputs,
  ...
}:
let
  l = theme.light;
  swaylockPackage = pkgs.swaylock-effects;

  # swaylock wants RRGGBB(AA) with no leading '#'
  swayColor = lib.removePrefix "#";

  # Idle *timeouts only* (warn -> lock, monitors-off, AC-guarded suspend). Lock,
  # unlock, and lock-before-sleep are owned by systemd-lock-handler + the
  # swaylock.service below; this script only decides WHEN to act on inactivity.
  # shellcheck runs on idle.sh at build via writeShellApplication
  idle = pkgs.writeShellApplication {
    name = "idle-session";
    runtimeInputs = with pkgs; [
      swayidle
      niri
      systemd
      coreutils
      libnotify
    ];
    text = builtins.readFile ./idle.sh;
  };
  brightnessd = pkgs.writers.writePython3Bin "brightnessd" {
    # makeWrapperArgs is passed straight through to makeScriptWriter, which
    # saves wrapping the result in a symlinkJoin by hand.
    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [
        pkgs.systemd # busctl
        pkgs.swayosd # swayosd-client
      ])
    ];
  } (builtins.readFile ./brightnessd.py);
in
{
  home.packages = with pkgs; [
    pavucontrol
    networkmanagerapplet
    kdePackages.ark
  ];

  programs = {
    waybar = {
      enable = true;
      systemd.enable = true;
      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 6;

        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-center = [ ];
        modules-right = [
          "idle_inhibitor"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "pulseaudio"
          "network"
          "power-profiles-daemon"
          "battery"
          "tray"
          "clock"
        ];

        "niri/workspaces".format = "{index}";
        "niri/window".max-length = 60;
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };
        cpu = {
          format = "󰻠  {usage}%";
          interval = 5;
        };
        memory.format = "󰍛  {percentage}%";
        temperature = {
          critical-threshold = 82;
          format = "{icon} {temperatureC}°C";
          format-icons = [
            "󱃃"
            "󰔏"
            "󱃂"
          ];
        };
        backlight = {
          format = "{icon}  {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃠"
          ];
        };
        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "󰝟  muted";
          format-icons.default = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        };
        network = {
          format-wifi = "󰖩  {essid}";
          format-ethernet = "󰈀  wired";
          format-disconnected = "󰤭  off";
          tooltip-format = "{ifname}: {ipaddr}";
          on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
        };
        "power-profiles-daemon" = {
          format = "{icon}";
          format-icons = {
            default = "󰗑";
            performance = "󰓅";
            balanced = "󰗑";
            "power-saver" = "󰌪";
          };
        };
        battery = {
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };
        clock = {
          interval = 1;
          align = 0;
          format = "{:%a %Y-%m-%d %H:%M:%S}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };
        tray = {
          spacing = 8;
          icon-size = 18;
        };
      };

      style =
        builtins.readFile "${inputs.flexoki}/waybar/flexoki-light.css"
        + builtins.readFile ./waybar-style.css;
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

        inside-color = swayColor l.bg2;
        ring-color = swayColor l.ui3;
        text-color = swayColor l.tx;
        line-color = swayColor l.bg;
        separator-color = swayColor l.bg2;
        key-hl-color = swayColor l.blue.base;
        bs-hl-color = swayColor l.red.base;

        inside-ver-color = swayColor l.bg2;
        ring-ver-color = swayColor l.cyan.base;
        text-ver-color = swayColor l.tx;

        inside-clear-color = swayColor l.bg2;
        ring-clear-color = swayColor l.yellow.base;
        text-clear-color = swayColor l.tx;

        inside-wrong-color = swayColor l.bg2;
        ring-wrong-color = swayColor l.red.base;
        text-wrong-color = swayColor l.tx;

        inside-caps-lock-color = swayColor l.bg2;
        ring-caps-lock-color = swayColor l.orange.base;
        text-caps-lock-color = swayColor l.tx;
        caps-lock-key-hl-color = swayColor l.blue.base;
        caps-lock-bs-hl-color = swayColor l.red.base;
      };
    };
  };

  services = {
    walker = {
      enable = true;
      package = pkgs.mollusca.walker;
      systemd.enable = true;
      enableElephantIntegration = true;
      theme = {
        name = "flexoki";
        # Walker has no upstream Flexoki port, so the stylesheet is custom:
        # derived @define-colors, then the structural CSS from ./walker-style.css.
        # Walker loads style.css wholesale, so this must be a complete stylesheet.
        style = ''
          @define-color window_bg_color ${l.bg};
          @define-color surface_bg_color ${l.bg2};
          @define-color accent_bg_color ${l.blue.base};
          @define-color theme_fg_color ${l.tx};
          @define-color subtle_fg_color ${l.tx2};
          @define-color border_color ${l.ui3};
          @define-color error_bg_color ${l.red.base};
          @define-color error_fg_color ${l.bg};
        ''
        + builtins.readFile ./walker-style.css;
      };
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
    batsignal = {
      enable = true;
      extraArgs = [
        "-w"
        "15" # "battery low"
        "-c"
        "10" # "battery very low"
        "-p" # emit charging/discharging on plug/unplug (transition-only)
        "-P"
        "Charging"
        "-U"
        "On battery"
        "-e" # let transient charge messages expire in swaync
      ];
    };
    playerctld.enable = true;

    # Night light. `tray = true` runs gammastep-indicator in the Waybar tray,
    # which provides the manual toggle (enable/disable + "suspend for 30m/1h/2h")
    # on top of the schedule. `provider = "manual"` avoids the geoclue dependency.
    gammastep = {
      enable = true;
      provider = "manual";
      latitude = 52.52;
      longitude = 13.405;
      tray = true;
      temperature = {
        day = 6500;
        night = 4000;
      };
    };

    # USB automount
    udiskie = {
      enable = true;
      tray = "auto";
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

  systemd.user = {
    # systemd owns the FIFO: it does the mkfifo, opens it O_RDWR | O_NONBLOCK
    # and validates S_ISFIFO before the daemon ever runs, so the FIFO exists
    # from login and no keypress hits a missing path. %t is $XDG_RUNTIME_DIR.
    sockets.brightnessd = {
      Unit.Description = "Brightness control FIFO";
      Socket = {
        ListenFIFO = "%t/brightness.fifo";
        SocketMode = "0600";
      };
      Install.WantedBy = [ "sockets.target" ];
    };

    services = {
      brightnessd = {
        Unit = {
          Description = "Coalescing brightness daemon";
          Requires = [ "brightnessd.socket" ];
          # Socket-activated, so the first keypress starts it -- by which point
          # niri has already run `systemctl --user import-environment NIRI_SOCKET`
          # (it waits for that before signalling READY). PartOf means it stops
          # with the session and is re-activated with a fresh NIRI_SOCKET if niri
          # restarts, rather than holding a stale socket path forever.
          After = [
            "brightnessd.socket"
            "graphical-session.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = builtins.trace (lib.getExe brightnessd) (lib.getExe brightnessd);
          Restart = "always";
          RestartSec = 1;
          Slice = "session.slice";
        };
      };

      elephant = {
        Unit = {
          Description = "Elephant - Data provider for application launchers";
          # By default elephant tries to start before niri and dies due to no Wayland socket.
          # TODO: suggest upstream?
          After = [ "niri.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart = lib.getExe pkgs.mollusca.elephant;
          Restart = "on-failure";
        };
      };

      # swaylock bound to lock.target (systemd-lock-handler). This is the single
      # lock path for manual, idle, lid, and pre-sleep locking; sleep.target is
      # ordered after lock.target, so the machine is provably locked before it
      # sleeps. Canonical unit from the nixpkgs systemd-lock-handler module docs.
      swaylock = {
        Unit = {
          Description = "Screen locker for Wayland";
          Documentation = [ "man:swaylock(1)" ];
          PartOf = [ "lock.target" ]; # stop when lock.target stops
          Before = [ "lock.target" ]; # delay lock.target until locked
          OnSuccess = [ "unlock.target" ]; # clean exit (unlock) -> unlock.target
        };
        Install.WantedBy = [ "lock.target" ];
        Service = {
          Type = "forking"; # swaylock -f forks only after locking
          ExecStart = "${lib.getExe swaylockPackage} -f";
          Restart = "on-failure";
          RestartSec = 0;
        };
      };

      # Idle timeouts only (warn -> lock, monitors-off, AC-guarded suspend). Policy
      # lives in ./idle.sh; lock/unlock/lock-before-sleep are handled by the targets.
      swayidle = {
        Unit = {
          Description = "Idle timeouts (warn, blank, suspend-then-hibernate)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart = lib.getExe idle;
          Restart = "on-failure";
        };
      };
    };
  };
  systemd.user.services = { };
}
