{
  pkgs,
  config,
  ...
}:
let
  swaylockPackage = pkgs.swaylock-effects;
in
{
  home = {
    packages = with pkgs; [
      gimp
      telegram-desktop
      signal-desktop
      spotify
      keepassxc
      discord
      protonvpn-gui
      obsidian
      dolphin-emu
      vlc
      shotwell
      gyre-fonts
      localsend
      openscad-unstable
      prusa-slicer
      thunderbird

      gdu
      htop
      fdupes
      koreader
    ];
    file = {
      ".local/share".source = config.lib.file.mkOutOfStoreSymlink config.xdg.dataHome;
      "${config.xdg.dataHome}/.keep".text = "";

      ".config".source = config.lib.file.mkOutOfStoreSymlink config.xdg.configHome;
      "${config.xdg.configHome}/.keep".text = "";

      ".local/state".source = config.lib.file.mkOutOfStoreSymlink config.xdg.stateHome;
      "${config.xdg.stateHome}/.keep".text = "";
    };
    language.base = "en_US.UTF-8";

    sessionVariables = {
      XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
      GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
      ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
    };

    stateVersion = "22.05";
  };

  xdg = {
    enable = true;
    configHome = config.home.homeDirectory + "/Configuration";
    dataHome = config.home.homeDirectory + "/Data";
    stateHome = config.home.homeDirectory + "/State";

    userDirs = {
      enable = true;
      createDirectories = true;
    };

    desktopEntries.kakoune-kitty = {
      name = "Kakoune (via Kitty)";
      genericName = "Text Editor";
      exec = "kitty kak %F";
      terminal = false;  # TODO: is this necessary?
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/plain"
        "text/markdown"
        "text/csv"
        "application/json"
      ];
    };

    mimeApps = {
      enable = true;
      defaultApplications =
        let
          images = "org.gnome.Shotwell-Viewer.desktop";
          av = "vlc.desktop";
          browser = "firefox.desktop";
          mail = "thunderbird.desktop";
          files = "org.kde.dolphin.desktop";
          archive = "org.kde.ark.desktop";
          text = "kakoune-kitty.desktop";
        in
        {
          "application/pdf" = "org.gnome.Evince.desktop";

          "text/plain" = text;
          "text/markdown" = text;
          "text/csv" = text;
          "application/json" = text;

          "image/jpeg" = images;
          "image/png" = images;
          "image/gif" = images;
          "image/webp" = images;
          "image/bmp" = images;
          "image/tiff" = images;

          "video/mp4" = av;
          "video/mpeg" = av;
          "video/webm" = av;
          "video/x-matroska" = av;
          "video/x-msvideo" = av;
          "video/quicktime" = av;
          "video/ogg" = av;
          "audio/mpeg" = av;
          "audio/flac" = av;
          "audio/ogg" = av;
          "audio/wav" = av;
          "audio/x-wav" = av;
          "audio/mp4" = av;

          "text/html" = browser;
          "application/xhtml+xml" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;

          "x-scheme-handler/mailto" = mail;
          "message/rfc822" = mail;
          "application/x-extension-eml" = mail;

          "inode/directory" = files;

          "application/zip" = archive;
          "application/x-tar" = archive;
          "application/x-compressed-tar" = archive;
          "application/x-bzip2-compressed-tar" = archive;
          "application/x-xz-compressed-tar" = archive;
          "application/gzip" = archive;
          "application/x-7z-compressed" = archive;
          "application/vnd.rar" = archive;
          "application/x-rar" = archive;
        };
    };
  };
  programs = {
    kakoune.enable = true;
    bash.enable = true;
    zsh.enable = true;
    fzf.enable = true;

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
        effect-blur = "20x10";
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
    playerctld.enable = true;

    # USB automount
    udiskie = {
      enable = true;
      tray = "auto";
    };

    # TODO: this works, but is somewhat too much for this file. Maybe turn into a
    # `mollusca` module with proper types?
    # Maybe someone already made a module I can add to my flake?
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
          lock.run = "${swaylockPackage}/bin/swaylock -f";
          displayOff.run = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          suspend.run = "${pkgs.systemd}/bin/systemctl suspend";
        };

        schedule = [
          {
            minutes = 5;
            battery = "dim";
            ac = null;
          }
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
                (
                  if b.run == a.run then
                    b.run
                  else
                    "if ${onBattery}; then ${b.run}; else ${a.run}; fi"
                )
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
            command = "${swaylockPackage}/bin/swaylock -f";
          }
        ];
        timeouts = map mkTimeout schedule;
      };
  };

  programs.niri.settings = let
    powerMenu = pkgs.writeShellApplication {
      name = "power-menu";
      runtimeInputs = [
        pkgs.fuzzel
        swaylockPackage
        pkgs.systemd
        pkgs.niri
      ];
      text = ''
        choice=$(printf '%s\n' Lock Logout Suspend Hibernate Reboot Shutdown \
          | fuzzel --dmenu --prompt 'Power: ')
        case "$choice" in
          Lock)      swaylock -f ;;
          Logout)    niri msg action quit ;;
          Suspend)   systemctl suspend ;;
          Hibernate) systemctl hibernate ;;
          Reboot)    systemctl reboot ;;
          Shutdown)  systemctl poweroff ;;
        esac
      '';
    };
  in
  { # TODO: remove tons of default config boilerplate
    prefer-no-csd = true;
    input = {
      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "10%";
      };
      keyboard.xkb = {
        layout = "eu,ru";
        variant = ",mac";
        # options = "grp:win_space_toggle";
        # options = "ctrl:nocaps";
      };

      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = false;
        click-method = "clickfinger";
      };
    };

    clipboard.disable-primary = true;

    spawn-at-startup = [
      { command = [ "${pkgs.waybar}/bin/waybar" ]; }
      {
        command = [
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "--indicator"
        ];
      }
      {
        command = [
          "${pkgs.wl-clip-persist}/bin/wl-clip-persist"
          "--clipboard"
          "regular"
          "--all-mime-type-regex"
          "'^(?!x-kde-passwordManagerHint).+'"
        ];
      }
    ];

    # Output (monitor) configuration
    outputs."eDP-1" = {
      scale = 1.75;
      mode = {
        width = 2880;
        height = 1920;
        refresh = 120.0;
      };
    };

    layout = {
      gaps = 16;

      focus-ring = {
        enable = true;
        width = 4;
        active.color = "#7fc8ff";
        inactive.color = "#505050";
      };

      border = {
        enable = false;

        width = 4;
        active.color = "#ffc87f";
        inactive.color = "#505050";

        urgent.color = "#9b0000";
      };

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];

      default-column-width.proportion = 0.5;

      center-focused-column = "never";
    };

    environment = {
      QT_QPA_PLATFORM = "wayland";
    };

    binds = with config.lib.niri.actions; {
      # Mod-Shift-/, which is usually the same as Mod-?,
      # shows a list of important hotkeys.
      "Mod+Shift+Slash".action = show-hotkey-overlay;

      # Suggested binds for running programs: terminal, app launcher, screen locker.
      "Mod+T" = {
        hotkey-overlay.title = "Open a Terminal: kitty";
        action.spawn = "kitty";
      };
      "Mod+D" = {
        hotkey-overlay.title = "Run an Application: fuzzel";
        action.spawn = "fuzzel";
      };
      "Super+Alt+L" = {
        hotkey-overlay.title = "Lock the Screen: swaylock";
        action.spawn = "swaylock";
      };
      "Mod+Shift+E" = {
        hotkey-overlay.title = "Power Menu";
        action.spawn = "${powerMenu}/bin/power-menu";
      };
      "Mod+N" = {
        hotkey-overlay.title = "Notification Menu";
        action.spawn = [
          "${pkgs.swaynotificationcenter}/bin/swaync-client"
          "--toggle-panel"
        ];
      };

      # Example volume keys mappings for PipeWire & WirePlumber.
      # The allow-when-locked = true property makes them work even when the session is locked.
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "swayosd-client"
          "--output-volume"
          "raise"
        ];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = [
          "swayosd-client"
          "--output-volume"
          "lower"
        ];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = [
          "swayosd-client"
          "--output-volume"
          "mute-toggle"
        ];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = [
          "swayosd-client"
          "--input-volume"
          "mute-toggle"
        ];
      };
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "swayosd-client"
          "--brightness"
          "raise"
        ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [
          "swayosd-client"
          "--brightness"
          "lower"
        ];
      };

      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = [
          "playerctl"
          "play-pause"
        ];
      };
      "XF86AudioPause" = {
        allow-when-locked = true;
        action.spawn = [
          "playerctl"
          "pause"
        ];
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = [
          "playerctl"
          "next"
        ];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = [
          "playerctl"
          "previous"
        ];
      };
      "XF86AudioStop" = {
        allow-when-locked = true;
        action.spawn = [
          "playerctl"
          "stop"
        ];
      };

      # Open/close the Overview: a zoomed-out view of workspaces and windows.
      # You can also move the mouse into the top-left hot corner,
      # or do a four-finger swipe up on a touchpad.
      "Mod+O" = {
        repeat = false;
        action = toggle-overview;
      };

      "Mod+Q" = {
        repeat = false;
        action = close-window;
      };

      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Right".action = focus-column-right;
      "Mod+H".action = focus-column-left;
      # "Mod+J".action = focus-window-down;
      # "Mod+K".action = focus-window-up;
      "Mod+J".action = focus-window-or-workspace-down;
      "Mod+K".action = focus-window-or-workspace-up;
      "Mod+L".action = focus-column-right;

      "Mod+Ctrl+Left".action = move-column-left;
      "Mod+Ctrl+Down".action = move-window-down;
      "Mod+Ctrl+Up".action = move-window-up;
      "Mod+Ctrl+Right".action = move-column-right;
      "Mod+Ctrl+H".action = move-column-left;
      # "Mod+Ctrl+J".action = move-window-down;
      # "Mod+Ctrl+K".action = move-window-up;
      "Mod+Ctrl+J".action = move-window-down-or-to-workspace-down;
      "Mod+Ctrl+K".action = move-window-up-or-to-workspace-up;
      "Mod+Ctrl+L".action = move-column-right;

      "Mod+Home".action = focus-column-first;
      "Mod+End".action = focus-column-last;
      "Mod+Ctrl+Home".action = move-column-to-first;
      "Mod+Ctrl+End".action = move-column-to-last;

      "Mod+Shift+Left".action = focus-monitor-left;
      "Mod+Shift+Down".action = focus-monitor-down;
      "Mod+Shift+Up".action = focus-monitor-up;
      "Mod+Shift+Right".action = focus-monitor-right;
      "Mod+Shift+H".action = focus-monitor-left;
      "Mod+Shift+J".action = focus-monitor-down;
      "Mod+Shift+K".action = focus-monitor-up;
      "Mod+Shift+L".action = focus-monitor-right;

      "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
      "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

      # Alternatively, there are commands to move just a single window:
      # Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
      # ...

      # And you can also move a whole workspace to another monitor:
      # Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
      # ...

      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+U".action = focus-workspace-down;
      "Mod+I".action = focus-workspace-up;
      "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
      "Mod+Ctrl+U".action = move-column-to-workspace-down;
      "Mod+Ctrl+I".action = move-column-to-workspace-up;

      "Mod+Shift+Page_Down".action = move-workspace-down;
      "Mod+Shift+Page_Up".action = move-workspace-up;
      "Mod+Shift+U".action = move-workspace-down;
      "Mod+Shift+I".action = move-workspace-up;

      # You can bind mouse wheel scroll ticks using the following syntax.
      # These binds will change direction based on the natural-scroll setting.
      #
      # To avoid scrolling through workspaces really fast, you can use
      # the cooldown-ms property. The bind will be rate-limited to this value.
      # You can set a cooldown on any bind, but it's most useful for the wheel.
      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action = focus-workspace-down;
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action = focus-workspace-up;
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action = move-column-to-workspace-down;
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action = move-column-to-workspace-up;
      };

      "Mod+WheelScrollRight".action = focus-column-right;
      "Mod+WheelScrollLeft".action = focus-column-left;
      "Mod+Ctrl+WheelScrollRight".action = move-column-right;
      "Mod+Ctrl+WheelScrollLeft".action = move-column-left;

      # Usually scrolling up and down with Shift in applications results in
      # horizontal scrolling; these binds replicate that.
      "Mod+Shift+WheelScrollDown".action = focus-column-right;
      "Mod+Shift+WheelScrollUp".action = focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

      # Similarly, you can bind touchpad scroll "ticks".
      # Touchpad scrolling is continuous, so for these binds it is split into
      # discrete intervals.
      # These binds are also affected by touchpad's natural-scroll, so these
      # example binds are "inverted", since we have natural-scroll enabled for
      # touchpads by default.
      # Mod+TouchpadScrollDown { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+"; }
      # Mod+TouchpadScrollUp   { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-"; }

      # You can refer to workspaces by index. However, keep in mind that
      # niri is a dynamic workspace system, so these commands are kind of
      # "best effort". Trying to refer to a workspace index bigger than
      # the current workspace count will instead refer to the bottommost
      # (empty) workspace.
      #
      # For example, with 2 workspaces + 1 empty, indices 3, 4, 5 and so on
      # will all refer to the 3rd workspace.
      "Mod+1".action.focus-workspace = [ 1 ];
      "Mod+2".action.focus-workspace = [ 2 ];
      "Mod+3".action.focus-workspace = [ 3 ];
      "Mod+4".action.focus-workspace = [ 4 ];
      "Mod+5".action.focus-workspace = [ 5 ];
      "Mod+6".action.focus-workspace = [ 6 ];
      "Mod+7".action.focus-workspace = [ 7 ];
      "Mod+8".action.focus-workspace = [ 8 ];
      "Mod+9".action.focus-workspace = [ 9 ];
      "Mod+Ctrl+1".action.move-column-to-workspace = [ 1 ];
      "Mod+Ctrl+2".action.move-column-to-workspace = [ 2 ];
      "Mod+Ctrl+3".action.move-column-to-workspace = [ 3 ];
      "Mod+Ctrl+4".action.move-column-to-workspace = [ 4 ];
      "Mod+Ctrl+5".action.move-column-to-workspace = [ 5 ];
      "Mod+Ctrl+6".action.move-column-to-workspace = [ 6 ];
      "Mod+Ctrl+7".action.move-column-to-workspace = [ 7 ];
      "Mod+Ctrl+8".action.move-column-to-workspace = [ 8 ];
      "Mod+Ctrl+9".action.move-column-to-workspace = [ 9 ];

      # Alternatively, there are commands to move just a single window:
      # Mod+Ctrl+1 { move-window-to-workspace 1; }

      # Switches focus between the current and the previous workspace.
      # Mod+Tab { focus-workspace-previous; }

      # The following binds move the focused window in and out of a column.
      # If the window is alone, they will consume it into the nearby column to the side.
      # If the window is already in a column, they will expel it out.
      "Mod+BracketLeft".action = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;

      # Consume one window from the right to the bottom of the focused column.
      "Mod+Comma".action = consume-window-into-column;
      # Expel the bottom window from the focused column to the right.
      "Mod+Period".action = expel-window-from-column;

      "Mod+R".action = switch-preset-column-width;
      # Cycling through the presets in reverse order is also possible.
      # Mod+R { switch-preset-column-width-back; }
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+Ctrl+R".action = reset-window-height;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;

      # Expand the focused column to space not taken up by other fully visible columns.
      # Makes the column "fill the rest of the space".
      "Mod+Ctrl+F".action = expand-column-to-available-width;

      "Mod+C".action = center-column;

      # Center all fully visible columns on screen.
      "Mod+Ctrl+C".action = center-visible-columns;

      # Finer width adjustments.
      # This command can also:
      # * set width in pixels: "1000"
      # * adjust width in pixels: "-5" or "+5"
      # * set width as a percentage of screen width: "25%"
      # * adjust width as a percentage of screen width: "-10%" or "+10%"
      # Pixel sizes use logical, or scaled, pixels. I.e. on an output with scale 2.0,
      # set-column-width "100" will make the column occupy 200 physical screen pixels.
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";

      # Finer height adjustments when in column with other windows.
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # Move the focused window between the floating and the tiling layout.
      "Mod+V".action = toggle-window-floating;
      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

      # Toggle tabbed column display mode.
      # Windows in this column will appear as vertical tabs,
      # rather than stacked on top of each other.
      "Mod+W".action = toggle-column-tabbed-display;

      # Actions to switch layouts.
      # Note: if you uncomment these, make sure you do NOT have
      # a matching layout switch hotkey configured in xkb options above.
      # Having both at once on the same hotkey will break the switching,
      # since it will switch twice upon pressing the hotkey (once by xkb, once by niri).
      "Mod+Space".action.switch-layout = "next";

      "Print".action.screenshot = { };
      "Ctrl+Print".action.screenshot-screen = { };
      "Alt+Print".action.screenshot-window = { };

      # Applications such as remote-desktop clients and software KVM switches may
      # request that niri stops processing the keyboard shortcuts defined here
      # so they may, for example, forward the key presses as-is to a remote machine.
      # It's a good idea to bind an escape hatch to toggle the inhibitor,
      # so a buggy application can't hold your session hostage.
      #
      # The allow-inhibiting = false property can be applied to other binds as well,
      # which ensures niri always processes them, even when an inhibitor is active.
      "Mod+Escape" = {
        allow-inhibiting = false;
        action = toggle-keyboard-shortcuts-inhibit;
      };

      # The quit action will show a confirmation dialog to avoid accidental exits.
      "Ctrl+Alt+Delete".action = quit;

      # Powers off the monitors. To turn them back on, do any input like
      # moving the mouse or pressing any other key.
      "Mod+Shift+P".action = power-off-monitors;
    };

    window-rules = [
      {
        matches = [
          {
            app-id = "^firefox$";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
      }
      {
        matches = [ { app-id = "^steam$"; } ];
        default-column-width = { }; # TODO: maybe unnecessary?
      }
      {
        matches = [
          {
            app-id = "^steam$";
            title = "^notificationtoasts_.*_desktop$";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
      }

    ];
  };

}
