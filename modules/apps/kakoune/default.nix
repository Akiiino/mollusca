{
  config,
  pkgs,
  lib,
  self,
  ...
}: let
  kakoune = pkgs.kakoune-unwrapped.overrideAttrs (oldAttrs: rec {
    version = "2025.06.03";
    src = pkgs.fetchFromGitHub {
      owner = "mawww";
      repo = "kakoune";
      rev = "v${version}";
      hash = "sha256-AJvh6NVFpbPsyzfeii/5muE+i4TwfxhwhDVgMLYOJCM=";
    };
  });
  clipb-kak = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
    pname = "clipb.kak";
    version = "2025-05-27";
    src = pkgs.fetchFromGitHub {
      owner = "Akiiino";
      repo = "clipb.kak";
      rev = "92f6ddb2933ba3855eece0b0013522b507b6167a";
      hash = "sha256-iW+P8arMUnwGH75h7TtUL4/5ykZcWpDxwvGmsG+Rp8U=";
    };
    meta.homepage = "https://github.com/Akiiino/clipb.kak";
  };
  parinfer-rust = pkgs.rustPlatform.buildRustPackage {
    pname = "parinfer-rust";
    version = "0.5.0";

    src = pkgs.fetchFromGitHub {
      owner = "Akiiino";
      repo = "parinfer-rust";
      rev = "e9b4c3365a5327288f57a494c042bdbabeea1be0";
      sha256 = "sha256-rS44hgB6Mi659MqIsu70b31nsZv0DVukrlB0Q8NjSO8=";
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
in {
  imports = [
  ];
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.wl-clipboard
  ];
  programs.kakoune = {
    enable = true;
    package = kakoune;
    defaultEditor = true;
    plugins = [
      clipb-kak
      pkgs.kakounePlugins.kak-ansi
      pkgs.kakounePlugins.powerline-kak
      parinfer-rust
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
            evaluate-commands %sh{ echo "set-option -add global ui_options %{terminal_title=$(basename \"$kak_hook_param\")}" }
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
            set-option buffer lintcmd "sh -c 'command -v proselint || echo ${lib.getExe pkgs.proselint}'"
            hook buffer BufWritePost .* %{
                lint-buffer
            }
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
      source ${./clipb-config.kak}
      source ${./powerline-config.kak}

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
