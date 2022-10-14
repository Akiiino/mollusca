# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      per-window = false;
      sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "ru+mac" ]) ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/interface" = {
      clock-show-seconds = true;
      clock-show-weekday = true;
      enable-hot-corners = false;
      gtk-enable-primary-paste = false;
      gtk-im-module = "gtk-im-context-simple";
      show-battery-percentage = true;
      text-scaling-factor = 1.25;
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      disable-while-typing = false;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/screensaver" = { lock-delay = mkUint32 0; };

    "org/gnome/desktop/search-providers" = {
      disabled = [ "org.gnome.clocks.desktop" ];
      sort-order = [
        "org.gnome.Contacts.desktop"
        "org.gnome.Documents.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/desktop/session" = { idle-delay = mkUint32 900; };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      focus-mode = "sloppy";
    };

    "org/gnome/desktop/remote-desktop/rdp" = { screen-share-mode = "extend"; };

    "org/gnome/mutter" = {
      attach-modal-dialogs = true;
      dynamic-workspaces = true;
      edge-tiling = true;
      focus-change-on-pointer-rest = true;
      workspaces-only-on-primary = false;
    };

    "org/gnome/shell" = {
      had-bluetooth-devices-setup = true;
      welcome-dialog-last-shown-version = "41.4";
    };

    "org/gnome/shell/world-clocks" = { locations = "@av []"; };

    "org/gnome/tweaks" = { show-extensions-notice = false; };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 157;
      sort-column = "name";
      sort-directories-first = true;
      sort-order = "ascending";
      type-format = "category";
      window-position = mkTuple [ 26 23 ];
      window-size = mkTuple [ 1128 673 ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/list-view" = { use-tree-view = true; };
  };
}
