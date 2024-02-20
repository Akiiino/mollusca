{
  config,
  lib,
  pkgs,
  self,
  nixpkgs,
  ...
}: let
  username = config.mollusca.secrets.workUsername;
  homeDirectory = "/Users/" + username;
  user = config.home-manager.users."${username}";
  nixcasks = import self.inputs.nixcasks {
    inherit nixpkgs pkgs;
    osVersion = "monterey";
  };
in {
  programs.zsh.enable = true;

  users.users.${username}.home = homeDirectory;
  home-manager.users."${username}" = {
    imports = [self.inputs.mac-app-util.homeManagerModules.default];
    xdg = {
      enable = true;
      configHome = homeDirectory + "/Configuration";
      dataHome = homeDirectory + "/Data";
      stateHome = homeDirectory + "/State";
    };
    programs = {
      zsh = {
        enable = true;
        dotDir = "Configuration/zsh";
        enableSyntaxHighlighting = true;
        history.path = user.xdg.stateHome + "/zsh/history";
        shellAliases = {
          ll = "eza --long --header --git --icons --classify --group-directories-first";
          lla = "eza --long --header --git --icons --classify --group-directories-first --all";
          lt = "ll --tree --level=2";
          lta = "lla --tree --level=2";
          lln = "ll --sort modified";
          ltn = "lt --sort modified";
          kdiff = "kitty +kitten diff";
          icat = "kitty +kitten icat";
        };

        envExtra = ''
          export $(cat /Audatic/environment)
        '';
        initExtra = ''
          setopt NO_CASE_GLOB
          kitty + complete setup zsh | source /dev/stdin

          # Case-insensitive completion
          zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

          autoload -U promptinit; promptinit; prompt pure

          clear_dsstore() {
              find ~ -name ".DS_Store" -delete
              find /Data/ -name ".DS_Store" -delete
              find /Configuration/ -name ".DS_Store" -delete
          }

          # [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
          eval "$(pyenv init -)"
        '';
      };
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
      fzf.enable = true;
      git = {
        enable = true;
        userName = "${config.mollusca.secrets.surname}, ${config.mollusca.secrets.name}";
        userEmail = config.mollusca.secrets.workEmail;
        lfs.enable = true;
        aliases = {
          "fpull" = "! f() { git fetch origin \"$1\":\"$1\"; }; f";
          "remote-main" = "! git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'";
          "move-branch" = "! f() { ONTO=$1 BRANCH=\${2:-$(git branch --show-current)} FROM=\${3:-$(git remote-main)}; git rebase --onto $ONTO $(git merge-base $FROM $BRANCH) $BRANCH; }; f";
        };
        extraConfig = {
          gitsh.historyFile = user.xdg.stateHome + "/gitsh/history";
          diff = {
            tool = "kitty";
            guitool = "kitty.gui";
          };
          difftool = {
            prompt = false;
            trustExitCode = true;
          };
          "difftool \"kitty\"".cmd = "kitty +kitten diff $LOCAL $REMOTE";
          "difftool \"kitty.gui\"".cmd = "kitty kitty +kitten diff $LOCAL $REMOTE";
          push.default = "current";
          blame.ignoreRevsFile = ".git-blame-ignore-revs";
          credential.helper = "osxkeychain";
        };
      };
      htop = {
        enable = true;
        settings.highlight_base_name = 1;
      };
      kitty = {
        enable = true;
        theme = "Gruvbox Light";
        settings = {
          "font_family" = "Iosevka Medium Extended";
          "bold_font" = "Iosevka Bold Extended";
          "italic_font" = "Iosevka Extended Oblique";
          "bold_italic_font" = "Iosevka Bold Extended Oblique";
          "font_size" = 16;

          "confirm_os_window_close" = 2;
          "placement_strategy" = "top-left";
          "hide_window_decorations" = false;
          "window_padding_width" = 10;
          "tab_bar_margin_width" = 8;

          "allow_remote_control" = true;
          "clear_all_shortcuts" = true;
          "focus_follows_mouse" = true;

          "symbol_map" =
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

          "adjust_line_height" = 0;
          "adjust_column_width" = 0;

          "disable_ligatures" = "always";

          "cursor_blink_interval" = 0;
          "cursor_shape" = "block";

          "window_resize_step_cells" = 1;
          "window_resize_step_lines" = 1;

          "enabled_layouts" = "splits:split_axis=vertical";

          "window_border_width" = "5pt";

          "draw_minimal_borders" = true;
          "inactive_text_alpha" = 1;

          "tab_bar_min_tabs" = 2;

          "tab_bar_style" = "custom";

          "tab_title_template" = "[{index}] {title}";
          "active_tab_font_style" = "bold";
          "inactive_tab_font_style" = "normal";

          "kitty_mod" = "super";
          "macos_option_as_alt" = "left";
        };
        keybindings = {
          "kitty_mod+c" = "copy_to_clipboard";
          "kitty_mod+v" = "paste_from_clipboard";

          "kitty_mod+k" = "scroll_line_up";
          "kitty_mod+j" = "scroll_line_down";
          "kitty_mod+page_up" = "scroll_page_up";
          "kitty_mod+page_down" = "scroll_page_down";
          "kitty_mod+home" = "scroll_home";
          "kitty_mod+end" = "scroll_end";

          "kitty_mod+n" = "new_os_window";

          "kitty_mod+[" = "launch --location=hsplit";
          "kitty_mod+]" = "launch --location=vsplit";

          "kitty_mod+enter" = "layout_action rotate";

          "kitty_mod+shift+up" = "move_window up";
          "kitty_mod+shift+left" = "move_window left";
          "kitty_mod+shift+right" = "move_window right";
          "kitty_mod+shift+down" = "move_window down";

          "kitty_mod+left" = "neighboring_window left";
          "kitty_mod+right" = "neighboring_window right";
          "kitty_mod+up" = "neighboring_window up";
          "kitty_mod+down" = "neighboring_window down";

          "kitty_mod+r" = "start_resizing_window";

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

          "kitty_mod+shift+;" = "kitty_shell window";
          "kitty_mod+delete" = "clear_terminal reset active";
          "f1" = "new_window_with_cwd";
        };
        environment = {
          "PATH" = "\${PATH}:/usr/local/bin:/bin";
          "LC_ALL" = "en_US.UTF-8";
          "LANG" = "en_US.UTF-8";
        };
      };
    };

    home = {
      inherit username homeDirectory;

      packages = [
        (self.inputs.autoraise.packages.x86_64-darwin.autoraise.override {experimental_focus_first = true;})
        (pkgs.unison.override {enableX11 = false;})

        pkgs.coreutils
        pkgs.curl
        pkgs.eza
        pkgs.fzf
        pkgs.jq
        pkgs.moreutils
        pkgs.openssl
        pkgs.tmux
        pkgs.wget

        pkgs.iina
        pkgs.monitorcontrol
        pkgs.spotify

        pkgs.slack
        pkgs.vault

        pkgs.kak-lsp
        pkgs.kakoune
        pkgs.shellcheck

        pkgs.pyenv

        pkgs.skhd

        nixcasks.keka
        nixcasks.jupyterlab
        nixcasks.jupyter-notebook-viewer
        nixcasks.notion
        nixcasks.rectangle-pro
        nixcasks.zotero
        nixcasks.mongodb-compass
        nixcasks.firefox
      ];

      stateVersion = "23.11";
    };
  };

  fonts = {
    fontDir.enable = true;
    fonts = [
      pkgs.fira-code
      (pkgs.nerdfonts.override {fonts = ["Hack"];})
      pkgs.iosevka
    ];
  };

  homebrew = {
    enable = true;
    global.autoUpdate = false;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    brews = [
      "pure"
      "pass"
    ];
    casks = [
      "logitech-options"
      "microsoft-teams"
    ];
  };

  nix.extraOptions = ''
    bash-prompt-prefix = (nix:$name)\040
    extra-nix-path = nixpkgs=flake:nixpkgs
    build-users-group = nixbld
  '';
  services.nix-daemon.enable = true;

  system.keyboard = {
    enableKeyMapping = true;
    nonUS.remapTilde = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
    LaunchServices.LSQuarantine = false;
    NSGlobalDomain = {
      AppleFontSmoothing = 1;
      AppleKeyboardUIMode = 3;
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Automatic";
      AppleTemperatureUnit = "Celsius";
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSDisableAutomaticTermination = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      NSTableViewDefaultSizeMode = 2;
      NSUseAnimatedFocusRing = false;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      "com.apple.springing.delay" = 0.0;
      "com.apple.springing.enabled" = true;
    };
    dock = {
      autohide = true;
      enable-spring-load-actions-on-all-items = true;
      expose-group-by-app = false;
      mru-spaces = false;
      orientation = "right";
      show-process-indicators = true;
      show-recents = false;
      tilesize = 75;
    };
    finder = {
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "clmv";
    };
    screencapture = {
      location = "/Data/Screenshots";
      type = "png";
    };
    universalaccess = {
      closeViewScrollWheelToggle = true;
    };
    CustomSystemPreferences = {
    };
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleAccentColor = 4;
        AppleHighlightColor = "0.698039 0.843137 1.000000 Blue";
        # AppleLanguages = ["en"];
        AppleLocale = "en_GB@currency=EUR";
        NSToolbarTitleViewRolloverDelay = 0;
        # NSUserDictionaryReplacementItems = [];
      };
      "com.apple.TextEdit" = {
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
        RichText = 0;
      };
      "com.apple.TimeMachine"."DoNotOfferNewDisksForBackup" = true;
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.dock" = {
        largesize = 100;
        magnification = true;
        # persistent-apps = [];
        pinning = "start";
      };
      "com.apple.finder" = {
        NewWindowTarget = "PfHm";
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;
      };
      "com.apple.frameworks.diskimages" = {
        skip-verify = true;
        skip-verify-locked = true;
        skip-verify-remote = true;
      };
      "com.apple.print.PrintingPrefs"."Quit When Finished" = true;
      # "com.apple.spotlight".orderedItems = [];
      "com.apple.universalaccess" = {
        closeViewSmoothImages = false;
        closeViewScrollWheelModifiersInt = 524288;
        reduceTransparency = false;
      };
    };
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      cmd + alt + ctrl + shift - k : kitty --single-instance -d ~
      cmd + alt + ctrl - j : open -a JupyterLab
      cmd + alt + ctrl - f : open -a Firefox
      cmd + alt + ctrl - k : open -a kitty
      cmd + alt + ctrl - p : ${(pkgs.writeShellScriptBin "write_pom" (builtins.readFile "${self}/scripts/write_pom"))}/bin/write_pom
    '';
  };

  system.stateVersion = 4;
}
