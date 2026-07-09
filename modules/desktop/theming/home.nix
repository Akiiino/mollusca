{
  pkgs,
  config,
  inputs,
  ...
}:
{
  gtk = {
    enable = true;
    colorScheme = "light";
    theme = {
      name = "flexoki";
      package = pkgs.mollusca.flexoki-gtk;
    };
    gtk4.theme = config.gtk.theme;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt6ctSettings.Appearance = {
      style = "Fusion";
      custom_palette = true;
      color_scheme_path = "${inputs.flexoki}/qt6ct/flexoki-light.conf";
    };
    qt5ctSettings.Appearance = config.qt.qt6ctSettings.Appearance;
  };

  gtk.font = {
    name = "Inter";
    size = 11;
  };

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Inter" ];
    monospace = [ "Iosevka" ];
  };

  home.pointerCursor = {
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 24;
    gtk.enable = true;
  };
}
