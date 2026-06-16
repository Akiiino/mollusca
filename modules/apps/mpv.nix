{ pkgs, ... }:
{
  # Migrated from the system-level `pkgs.mpv.override { scripts = [...]; }` that
  # used to live in machines/aspersum/default.nix. mpv otherwise runs on its
  # built-in defaults; grow `config`/`bindings` here as needed.
  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.autoload ];

    # TODO: two scripts still live imperatively in ~/.config/mpv/scripts on
    # aspersum (delete_file.lua, mpv-trimmer.lua). Add them here — package their
    # contents (e.g. via pkgs.writeTextDir) into `scripts`, or swap for nixpkgs
    # `mpvScripts.*` equivalents — to make mpv fully declarative.
    config = { };
  };
}
