{
  config,
  pkgs,
  lib,
  self,
  inputs',
  ...
}:
let
  kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: rec {
    version = "2025.06.03";
    src = self.inputs.kakoune;
  });
in
{
  programs.kakoune = {
    enable = true;
    package = kakoune;
    defaultEditor = true;
    plugins = [
      pkgs.kakounePlugins.kak-ansi
      pkgs.kakounePlugins.powerline-kak
      pkgs.kakounePlugins.openscad-kak
      inputs'.parinfer-rust.packages.parinfer-rust
      inputs'.kak-yac.packages.kak-yac
    ];
    config = {
      colorScheme = "gruvbox-light";
      ui = {
        assistant = "none";
        enableMouse = true;
        statusLine = "top";
      };
      scrollOff = {
        columns = 3;
        lines = 1;
      };
      showMatching = true;
      hooks = [
        {
          name = "WinDisplay";
          option = ".*";
          commands = ''
            evaluate-commands %sh{ printf "%s" "set-option -add global ui_options %{terminal_title=$(basename "$kak_hook_param")}" }
          '';
          once = false;
        }
        {
          name = "WinSetOption";
          option = "filetype=(janet)";
          commands = "parinfer-enable-window -smart";
          group = "parinfer";
          once = false;
        }
        {
          name = "WinSetOption";
          option = "filetype=(markdown)";
          commands = ''
            source ${./markdown.kak} "${lib.getExe pkgs.proselint}"
          '';
          once = false;
        }
        # {
        #   name = "KakBegin";
        #   option = ".*";
        #   commands = "set-option global kitty_window_type os-window";
        #   once = true;
        # }
      ];

      keyMappings = [
        {
          mode = "user";
          key = "/";
          effect = ": comment-line<ret>";
          docstring = "Comment line";
        }
        {
          mode = "user";
          key = "?";
          effect = ": comment-block<ret>";
          docstring = "Comment block";
        }
      ];
    };
    extraConfig = ''
      source ${./powerline-config.kak}
      source ${./utils.kak}

      set-option global startup_info_version 20240518
      set-option -add global ui_options terminal_set_title=true

      yac-enable

      define-command -docstring "Prepare windows for IDE mode" ide %{
          rename-client main
          set global jumpclient main

          new rename-client tools
          set global toolsclient tools

          new rename-client docs
          set global docsclient docs
      }

      define-command -docstring "Open the tutorial" trampoline %{
          evaluate-commands %sh{
              tramp_file=$(mktemp -t "kakoune-trampoline.XXXXXXXX")
              echo "edit -fifo $tramp_file *TRAMPOLINE*"
              curl -s https://raw.githubusercontent.com/mawww/kakoune/master/contrib/TRAMPOLINE -o "$tramp_file"
          }
      }

      define-command undefine-command -params 1 -docstring "Undefine a command by replacing it with a hidden nop" %{
          define-command -override -hidden "%arg{1}" "nop"
      }
    '';
  };
}
