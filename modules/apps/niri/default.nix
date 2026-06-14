{ pkgs, lib, ... }:
{
  imports = [ ./binds.nix ];

  programs.niri.settings = {
    # TODO: remove tons of default config boilerplate
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
      {
        command = [
          (lib.getExe pkgs.waybar)
        ];
      }
      {
        command = [
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "--indicator"
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
