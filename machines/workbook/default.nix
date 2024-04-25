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
  hmUser = config.home-manager.users."${username}";
  nixcasks = import self.inputs.nixcasks {
    inherit nixpkgs pkgs;
    osVersion = "monterey";
  };
in {
  programs.zsh.enable = true;

  users.users.${username}.home = homeDirectory;
  home-manager.extraSpecialArgs = {inherit self;};
  home-manager.users."${username}" = {
    imports = [
      self.inputs.mac-app-util.homeManagerModules.default
      "${self}/modules/apps/kitty.nix"
      "${self}/modules/apps/zsh.nix"
      "${self}/modules/apps/direnv.nix"
      "${self}/modules/apps/starship.nix"
    ];
    xdg = {
      enable = true;
      configHome = homeDirectory + "/Configuration";
      dataHome = homeDirectory + "/Data";
      stateHome = homeDirectory + "/State";
    };
    programs = {
      kitty.font.size = 16;
      zsh = {
        envExtra = ''
          export $(cat /Audatic/environment)
        '';
        initExtra = ''
          clear_dsstore() {
              find ~ -name ".DS_Store" -delete
              find /Data/ -name ".DS_Store" -delete
              find /Configuration/ -name ".DS_Store" -delete
          }

          # [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
          eval "$(pyenv init -)"
        '';
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
          gitsh.historyFile = hmUser.xdg.stateHome + "/gitsh/history";
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
    };

    home = {
      inherit username homeDirectory;

      sessionVariables = {
        RUFF_CACHE_DIR = hmUser.xdg.cacheHome + "/ruff";
      };

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
        pkgs.localsend

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
