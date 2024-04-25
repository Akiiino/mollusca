{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = rec {
      ll = "${lib.getExe pkgs.eza} --long --header --git --icons --classify --group-directories-first";
      lla = "${ll} --all";
      lt = "${ll} --tree --level=2";
      lta = "${lt} --all";
      lln = "${ll} --sort modified";
      ltn = "${lt} --sort modified";
      kdiff = "kitty +kitten diff";
      icat = "kitty +kitten icat";
    };

    initExtra = ''
      setopt NO_CASE_GLOB
      kitty + complete setup zsh | source /dev/stdin

      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'
    '';
  };
}
