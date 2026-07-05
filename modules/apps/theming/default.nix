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
}
