{
  self,
  pkgs,
  lib,
  theme,
  ...
}:
let
  l = theme.light;

  wallpaper =
    let
      ink = theme.base."850";
      bg = theme.base."150";
    in
    pkgs.runCommandLocal "flexoki-wallpaper.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick ${self}/modules/desktop/niri/wallpaper-base.png +level-colors '${ink}','${bg}' PNG:"$out"
    '';
in
{
  imports = [ ./binds.nix ];

  programs.niri.settings = {
    # TODO: remove tons of default config boilerplate
    prefer-no-csd = true;

    # niri draws its own compositor cursor (it doesn't read home.pointerCursor),
    # so mirror the phinger-cursors dark theme here.
    # TODO: any way to consolidate?
    cursor = {
      theme = "phinger-cursors-dark";
      size = 24;
    };
    input = {
      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "10%";
      };
      keyboard.xkb = {
        layout = "eu,ru";
        variant = ",mac";
        options = "caps:escape";
      };

      touchpad = {
        tap = true;
        natural-scroll = true;
        dwt = false; # disable when typing
        click-method = "clickfinger";
      };
    };

    clipboard.disable-primary = true;

    spawn-at-startup = [
      # TODO: make these into proper services
      {
        command = [
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "--indicator"
        ];
      }
      {
        command = [
          (lib.getExe pkgs.swaybg)
          "-m"
          "fill"
          "-i"
          "${wallpaper}"
        ];
      }
    ];

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
        active.color = l.blue.base;
        inactive.color = l.ui3;
      };

      border = {
        enable = false;

        width = 4;
        active.color = l.orange.base;
        inactive.color = l.ui3;

        urgent.color = l.red.base;
      };

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];

      default-column-width.proportion = 0.5;

      center-focused-column = "never";
      always-center-single-column = true;
      empty-workspace-above-first = true;
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
        matches = [
          {
            app-id = "^steam$";
            title = "^notificationtoasts_.*_desktop$";
          }
        ];
        default-floating-position = {
          x = 3;
          y = 3;
          relative-to = "bottom-right";
        };
      }

    ];
  };
}
