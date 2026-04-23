{
  pkgs,
  lib,
  ...
}:
{
  programs.kitty = {
    enable = true;
    themeFile = "gruvbox-light";
    font = {
      package = pkgs.iosevka;
      name = "Iosevka Medium Extended";
      size = lib.mkDefault 14;
    };
    settings = {
      font_family = "Iosevka Medium Extended";
      bold_font = "Iosevka Bold Extended";
      italic_font = "Iosevka Extended Oblique";
      bold_italic_font = "Iosevka Bold Extended Oblique";
      allow_remote_control = true;
      symbol_map =
        lib.concatStringsSep "," [
          "U+E5FA-U+E62B"
          "U+E700-U+E7C5"
          "U+F000-U+F2E0"
          "U+E200-U+E2A9"
          "U+F500-U+FD46"
          "U+E300-U+E3EB"
          "U+F400-U+F4A8"
          "U+2665"
          "U+26A1"
          "U+F27C"
          "U+E0A3"
          "U+E0B4-U+E0C8"
          "U+E0CA"
          "U+E0CC-U+E0D2"
          "U+E0D4"
          "U+23FB-U+23FE"
          "U+2B58"
          "U+F300-U+F313"
          "U+E000-U+E00D"
        ]
        + " Hack Nerd Font Mono Regular";
      confirm_os_window_close = 2;
      placement_strategy = "center";
      hide_window_decorations = true;
      window_padding_width = 10;
      disable_ligatures = "always";
      tab_bar_min_tabs = 1;

      tab_bar_style = "powerline";
      tab_powerline_style = "angled";

      tab_title_template = "[{index}] {title}";

      active_tab_foreground = "#fbf1c7";
      active_tab_background = "#3c3836";
      active_tab_font_style = "bold";
      inactive_tab_foreground = "#282828";
      inactive_tab_background = "#a89984";
      inactive_tab_font_style = "normal";
      tab_bar_background = "#d5c4a1";
      active_border_color = "#3c3836";
      inactive_border_color = "#7c6f64";
      bell_border_color = "#fb4934";

      window_border_width = "5pt";

      draw_minimal_borders = true;
      inactive_text_alpha = "1";

      window_resize_step_cells = 1;
      window_resize_step_lines = 1;
      enabled_layouts = "splits:split_axis=vertical";
      focus_follows_mouse = true;

      kitty_mod = lib.mkDefault "super";
      macos_option_as_alt = "left";

      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";

      clear_all_shortcuts = true;
    };
    keybindings = {
      #: Clipboard

      "kitty_mod+c" = "copy_to_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";

      #: Scrolling

      "kitty_mod+k" = "scroll_line_up";
      "kitty_mod+j" = "scroll_line_down";
      "kitty_mod+page_up" = "scroll_page_up";
      "kitty_mod+page_down" = "scroll_page_down";
      "kitty_mod+home" = "scroll_home";
      "kitty_mod+end" = "scroll_end";

      "kitty_mod+s" = "show_scrollback";

      "kitty_mod+n" = "new_os_window";

      "kitty_mod+[" = "launch --location=hsplit";
      "kitty_mod+]" = "launch --location=vsplit";

      "kitty_mod+enter" = "layout_action rotate";

      "kitty_mod+alt+up" = "move_window up";
      "kitty_mod+alt+left" = "move_window left";
      "kitty_mod+alt+right" = "move_window right";
      "kitty_mod+alt+down" = "move_window down";

      "kitty_mod+left" = "neighboring_window left";
      "kitty_mod+right" = "neighboring_window right";
      "kitty_mod+up" = "neighboring_window up";
      "kitty_mod+down" = "neighboring_window down";

      "kitty_mod+r" = "start_resizing_window";

      #: Tab management

      "kitty_mod+t" = "new_tab";
      "kitty_mod+." = "move_tab_forward";
      "kitty_mod+," = "move_tab_backward";
      "kitty_mod+alt+t" = "set_tab_title";

      "kitty_mod+1" = "goto_tab 1";
      "kitty_mod+2" = "goto_tab 2";
      "kitty_mod+3" = "goto_tab 3";
      "kitty_mod+4" = "goto_tab 4";
      "kitty_mod+5" = "goto_tab 5";
      "kitty_mod+6" = "goto_tab 6";
      "kitty_mod+7" = "goto_tab 7";
      "kitty_mod+8" = "goto_tab 8";
      "kitty_mod+9" = "goto_tab 9";
      "kitty_mod+0" = "goto_tab 10";

      #: Font sizes

      "kitty_mod+equal" = "change_font_size all +2.0";
      "kitty_mod+plus" = "change_font_size all +2.0";
      "kitty_mod+kp_add" = "change_font_size all +2.0";
      "kitty_mod+minus" = "change_font_size all -2.0";
      "kitty_mod+kp_subtract" = "change_font_size all -2.0";
      "kitty_mod+backspace" = "change_font_size all 0";

      "kitty_mod+u" = "kitten unicode_input";
      "kitty_mod+alt+;" = "kitty_shell window";
      "kitty_mod+delete" = "clear_terminal reset active";

      "ctrl+shift+f6" = "debug_config";
    };
  };
}
