{
  config,
  pkgs,
  lib,
  ...
}: {
  programs. direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    stdlib = ''
      declare -A direnv_layout_dirs
      direnv_layout_dir() {
          local hash path
          echo "''${direnv_layout_dirs[$PWD]:=$(
              hash="$(sha1sum - <<< "$PWD" | head -c40)"
              path="''${PWD//[^a-zA-Z0-9]/-}"
              echo "${config.xdg.cacheHome}/direnv/layouts/''${hash}''${path}"
          )}"
      }
    '';
  };
}

