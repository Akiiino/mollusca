{
  config,
  pkgs,
  lib,
  ...
}:
let
  powerMenu = pkgs.writeShellApplication {
    name = "power-menu";
    runtimeInputs = [
      pkgs.swaylock-effects
      pkgs.systemd
      config.programs.niri.package
      pkgs.fuzzel
    ];
    text = ''
      choice=$(printf '%s\n' Lock Logout Suspend Hibernate Reboot Shutdown \
        | fuzzel --dmenu --prompt 'Power: ')
      case "$choice" in
        Lock)      loginctl lock-session ;;
        Logout)    niri msg action quit ;;
        Suspend)   systemctl suspend ;;
        Hibernate) systemctl hibernate ;;
        Reboot)    systemctl reboot ;;
        Shutdown)  systemctl poweroff ;;
      esac
    '';
  };

  # One line per keypress. `1<>` opens the FIFO read-write, which never blocks
  # even with no reader, so a wedged daemon cannot hang a keybind. The -p guard
  # means a stopped socket unit makes the keys a silent no-op rather than
  # creating a regular file where the FIFO belongs.
  brightness = pkgs.writeShellApplication {
    name = "brightness";
    text = ''
      step=''${1:?usage: brightness <+/-N>}
      fifo=''${XDG_RUNTIME_DIR:-/tmp}/brightness.fifo
      [[ -p $fifo ]] || exit 0
      printf '%s\n' "$step" 1<>"$fifo"
    '';
  };
in
{
  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+Shift+Slash".action = show-hotkey-overlay;

    "Mod+T" = {
      hotkey-overlay.title = "Open a Terminal: kitty";
      action.spawn = lib.getExe pkgs.kitty;
    };
    "Mod+Shift+D" = {
      hotkey-overlay.title = "Run an Application: fuzzel";
      action.spawn = lib.getExe pkgs.fuzzel;
    };
    "Mod+D" = {
      hotkey-overlay.title = "Run an Application: walker";
      action.spawn = lib.getExe config.services.walker.package;
    };
    "Mod+Tab" = {
      hotkey-overlay.title = "Switch Window: walker";
      action.spawn = [
        (lib.getExe config.services.walker.package)
        "--provider"
        "windows"
      ];
    };
    "Mod+Shift+C" = {
      hotkey-overlay.title = "Clipboard History: walker";
      action.spawn = [
        (lib.getExe config.services.walker.package)
        "--provider"
        "clipboard"
      ];
    };
    "Mod+Semicolon" = {
      hotkey-overlay.title = "Emoji & Symbols: walker";
      action.spawn = [
        (lib.getExe config.services.walker.package)
        "--provider"
        "symbols"
      ];
    };
    "Mod+Alt+L" = {
      hotkey-overlay.title = "Lock the Screen";
      action.spawn = [
        (lib.getExe' pkgs.systemd "loginctl")
        "lock-session"
      ];
    };
    "Mod+Shift+E" = {
      hotkey-overlay.title = "Power Menu";
      action.spawn = lib.getExe powerMenu;
    };
    "Mod+N" = {
      hotkey-overlay.title = "Notification Menu";
      action.spawn = [
        (lib.getExe' pkgs.swaynotificationcenter "swaync-client")
        "--toggle-panel"
      ];
    };

    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe' pkgs.swayosd "swayosd-client")
        "--output-volume"
        "raise"
      ];
    };
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe' pkgs.swayosd "swayosd-client")
        "--output-volume"
        "lower"
      ];
    };
    "Shift+XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe' pkgs.swayosd "swayosd-client")
        "--output-volume"
        "+1"
      ];
    };
    "Shift+XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe' pkgs.swayosd "swayosd-client")
        "--output-volume"
        "-1"
      ];
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe' pkgs.swayosd "swayosd-client")
        "--output-volume"
        "mute-toggle"
      ];
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe' pkgs.swayosd "swayosd-client")
        "--input-volume"
        "mute-toggle"
      ];
    };
    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe brightness)
        "+10"
      ];
    };
    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe brightness)
        "-10"
      ];
    };
    "Shift+XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe brightness)
        "+1"
      ];
    };
    "Shift+XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe brightness)
        "-1"
      ];
    };

    "XF86AudioPlay" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe pkgs.playerctl)
        "play-pause"
      ];
    };
    "XF86AudioPause" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe pkgs.playerctl)
        "pause"
      ];
    };
    "XF86AudioNext" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe pkgs.playerctl)
        "next"
      ];
    };
    "XF86AudioPrev" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe pkgs.playerctl)
        "previous"
      ];
    };
    "XF86AudioStop" = {
      allow-when-locked = true;
      action.spawn = [
        (lib.getExe pkgs.playerctl)
        "stop"
      ];
    };

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
    "Mod+J".action = focus-window-or-workspace-down;
    "Mod+K".action = focus-window-or-workspace-up;
    "Mod+L".action = focus-column-right;

    "Mod+Ctrl+Left".action = move-column-left;
    "Mod+Ctrl+Down".action = move-window-down;
    "Mod+Ctrl+Up".action = move-window-up;
    "Mod+Ctrl+Right".action = move-column-right;
    "Mod+Ctrl+H".action = move-column-left;
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

    "Mod+Page_Down".action = focus-workspace-down;
    "Mod+Page_Up".action = focus-workspace-up;
    "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
    "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
    "Mod+Ctrl+U".action = move-column-to-workspace-down;
    "Mod+Ctrl+I".action = move-column-to-workspace-up;

    "Mod+Shift+Page_Down".action = move-workspace-down;
    "Mod+Shift+Page_Up".action = move-workspace-up;
    "Mod+Shift+U".action = move-workspace-down;
    "Mod+Shift+I".action = move-workspace-up;

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

    "Mod+Shift+WheelScrollDown".action = focus-column-right;
    "Mod+Shift+WheelScrollUp".action = focus-column-left;
    "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
    "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

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

    "Mod+BracketLeft".action = consume-or-expel-window-left;
    "Mod+BracketRight".action = consume-or-expel-window-right;

    "Mod+Comma".action = consume-window-into-column;
    "Mod+Period".action = expel-window-from-column;

    "Mod+R".action = switch-preset-column-width;
    "Mod+Shift+R".action = switch-preset-window-height;
    "Mod+Ctrl+R".action = reset-window-height;
    "Mod+F".action = maximize-column;
    "Mod+Shift+F".action = fullscreen-window;

    "Mod+Ctrl+F".action = expand-column-to-available-width;

    "Mod+C".action = center-column;
    "Mod+Ctrl+C".action = center-visible-columns;

    "Mod+Minus".action = set-column-width "-10%";
    "Mod+Equal".action = set-column-width "+10%";

    "Mod+Shift+Minus".action = set-window-height "-10%";
    "Mod+Shift+Equal".action = set-window-height "+10%";

    "Mod+V".action = toggle-window-floating;
    "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

    "Mod+W".action = toggle-column-tabbed-display;

    "Mod+Space".action.switch-layout = "next";

    "Print".action.screenshot = { };
    "Ctrl+Print".action.screenshot-screen = { };
    "Alt+Print".action.screenshot-window = { };

    # Escape hatch for the shortcuts inhibitor (remote-desktop clients etc.),
    # so a buggy application can't hold the session hostage.
    "Mod+Escape" = {
      allow-inhibiting = false;
      action = toggle-keyboard-shortcuts-inhibit;
    };

    "Ctrl+Alt+Delete".action = quit;

    "Mod+Shift+P".action = power-off-monitors;
  };
}
