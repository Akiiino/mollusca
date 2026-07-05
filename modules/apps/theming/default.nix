{
  pkgs,
  config,
  inputs,
  ...
}:
{
  gtk = {
    enable = true;
    # Light variant everywhere: dconf color-scheme (Firefox and libadwaita
    # follow it) plus the gtk4 settings.ini key.
    colorScheme = "light";
    theme = {
      name = "flexoki";
      package = pkgs.mollusca.flexoki-gtk;
    };
    # GTK4/libadwaita ignore the theme name but respect user CSS; home-manager's
    # gtk4 module @imports the theme's gtk-4.0/gtk.css into ~/.config/gtk-4.0.
    # Point it at the same Flexoki theme (also silences the legacy-default warning).
    gtk4.theme = config.gtk.theme;
  };

  # Qt: route Qt apps through qt6ct with the Fusion style + Flexoki palette.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt6ctSettings.Appearance = {
      style = "Fusion";
      custom_palette = true;
      # Read the palette straight from the flexoki input in the store.
      color_scheme_path = "${inputs.flexoki}/qt6ct/flexoki-light.conf";
    };
    # Qt5 apps (e.g. VLC) go through qt5ct; same [ColorScheme] format.
    qt5ctSettings.Appearance = config.qt.qt6ctSettings.Appearance;
  };

  gtk.font = {
    name = "Inter";
    size = 11;
  };

  # home-manager's fonts.fontconfig has no defaultFonts option, so map the
  # generic families to our picks with a user fontconfig drop-in. This is
  # akiiino-scoped, so it never touches nautilus's other users.
  xdg.configFile."fontconfig/conf.d/52-akiiino-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias><family>sans-serif</family><prefer><family>Inter</family></prefer></alias>
      <alias><family>monospace</family><prefer><family>Iosevka</family></prefer></alias>
    </fontconfig>
  '';

  # Cursor: phinger-cursors dark variant (contrast on the light Flexoki bg).
  # Covers GTK/XWayland apps and writes ~/.icons/default; niri's own compositor
  # cursor is set separately in the niri module.
  home.pointerCursor = {
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 24;
    gtk.enable = true;
  };
}
