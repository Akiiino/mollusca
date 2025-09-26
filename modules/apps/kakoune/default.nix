{
  config,
  pkgs,
  lib,
  self,
  ...
}:
let
  kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: rec {
    version = "2025.06.03";
    src = pkgs.fetchFromGitHub {
      repo = "kakoune";
      owner = "mawww";
      rev = "e3263887653ce5ec817c1aad51389c9600dfeabe";
      hash = "sha256-wDYQ1OVEKeE19UDFfCVS71AdsowCPuft3Jksu47tPJA=";
    };
  });
  kakoune-osc52 = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
    pname = "kakoune-osc52";
    version = "2025-06-17";
    src = pkgs.fetchFromGitHub {
      owner = "Akiiino";
      repo = "kakoune-osc52";
      rev = "664fc2b4e58188b0f1d2faea3cd8a2d66bfe6d62";
      hash = "sha256-aqI31Z0i+LlSrlnc9Q1FJmdAOndmcLFBsyatRaiWv34=";
    };
    meta.homepage = "https://github.com/Akiiino/kakoune-osc52";
  };
  parinfer-rust = pkgs.rustPlatform.buildRustPackage {
    pname = "parinfer-rust";
    version = "0.5.0";

    src = pkgs.fetchFromGitHub {
      owner = "eraserhd";
      repo = "parinfer-rust";
      rev = "afe6b1176cd805c000713e23b654fbf4b9f4b156";
      sha256 = "sha256-YKja8nIWmPBNsHboJGXGyZKsjFRZPUOd6rOpPinqg4M=";
    };
    useFetchCargoVendor = true;
    cargoHash = "sha256-sgqzAFZmfpacyjDOvJNyj3IwQGTTKcxV9bHzNCSm6Ig=";

    nativeBuildInputs = [
      pkgs.llvmPackages.clang
      pkgs.rustPlatform.bindgenHook
    ];

    postInstall = ''
      mkdir -p $out/share/kak/autoload/plugins
      cp rc/parinfer.kak $out/share/kak/autoload/plugins/

      rtpPath=$out/plugin
      mkdir -p $rtpPath
      sed "s,let s:libdir = .*,let s:libdir = '${placeholder "out"}/lib'," \
        plugin/parinfer.vim > $rtpPath/parinfer.vim
    '';
  };
in
{
  programs.kakoune = {
    enable = true;
    package = kakoune;
    defaultEditor = true;
    plugins = [
      pkgs.kakounePlugins.kak-ansi
      pkgs.kakounePlugins.powerline-kak
      parinfer-rust
      kakoune-osc52
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
      source ${./kakoune-osc52-config.kak}
      source ${./powerline-config.kak}
      source ${./utils.kak}

      set-option global startup_info_version 20240518
      set-option -add global ui_options terminal_set_title=true

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

      #set-option global rainbow_colors rgb:CC241D rgb:D65D0E rgb:98971A rgb:D79921 rgb:458588 rgb:B16286
    '';
  };
}
