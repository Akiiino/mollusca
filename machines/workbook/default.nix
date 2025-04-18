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
    osVersion = "sequoia";
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
      "${self}/modules/apps/firefox"
    ];
    # launchd.agents.activate-user = {
    #   enable = true;
    #   config = {
    #     Program = "/bin/sh";
    #     ProgramArguments = ["-c" "exec /run/current-system/activate-user"];
    #     RunAtLoad = true;
    #     KeepAlive.SuccessfulExit = false;
    #   };
    # };
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
          export $(cat ${homeDirectory}/Audatic/environment)
        '';
        initExtra = ''
          clear_dsstore() {
              find . -name ".DS_Store" -delete
          }
        '';
      };
      firefox.package = nixcasks.firefox;
      fzf.enable = true;
      git = {
        enable = true;
        userName = "${config.mollusca.secrets.surname}, ${config.mollusca.secrets.name}";
        userEmail = config.mollusca.secrets.workEmail;
        lfs.enable = true;
        aliases = {
          "git" = "! cd -- \${GIT_PREFIX:-.} && git";
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

      file = {
        ".mongodb".source = hmUser.lib.file.mkOutOfStoreSymlink (hmUser.xdg.stateHome + "/mongodb");
        "${hmUser.xdg.stateHome}/mongodb/.keep".text = "";

        "${hmUser.home.homeDirectory}/Home/.keep".text = "";

        "${hmUser.xdg.stateHome}/gitsh/.keep".text = "";

        "Audatic".source = hmUser.lib.file.mkOutOfStoreSymlink "/mnt/home/npopov/Audatic";
      };

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
        pkgs.keepassxc

        pkgs.slack
        pkgs.vault

        pkgs.kak-lsp
        pkgs.kakoune
        pkgs.shellcheck

        pkgs.skhd

        nixcasks.keka
        nixcasks.jupyter-notebook-viewer
        nixcasks.notion
        nixcasks.zotero
        nixcasks.mongodb-compass
        nixcasks.middleclick
      ];

      stateVersion = "23.11";
    };
  };

  fonts = {
    packages = [
      pkgs.fira-code
      pkgs.nerd-fonts.hack
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
    casks = [
      "logi-options+"
      "microsoft-teams"
      "microsoft-outlook"
      "rectangle-pro"
      "docker"
    ];
  };

  nix.extraOptions = ''
    bash-prompt-prefix = (nix:$name)\040
    extra-nix-path = nixpkgs=flake:nixpkgs
    build-users-group = nixbld
  '';

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
      expose-group-apps = false;
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
      location = hmUser.xdg.dataHome + "/Screenshots";
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
        AppleLocale = "en_DE";
        NSToolbarTitleViewRolloverDelay = 0;
        NSUserDictionaryReplacementItems = [];
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
        persistent-apps = [];
        persistent-others = [];
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

  launchd.user.envVariables = {
    XDG_CONFIG_HOME = hmUser.xdg.configHome;
    XDG_DATA_HOME = hmUser.xdg.configHome;

    # todo: simplify with a module
    IPYTHONDIR = "${hmUser.xdg.configHome}/jupyter";
    JUPYTER_CONFIG_DIR = "${hmUser.xdg.configHome}/jupyter";
    KERAS_HOME = "${hmUser.xdg.configHome}/keras";
    LESSKEY = "${hmUser.xdg.configHome}/less/lesskey";
    MPLCONFIGDIR = "${hmUser.xdg.configHome}/matplotlib";
    PARALLEL_HOME = "${hmUser.xdg.configHome}/parallel";
    VAULT_CONFIG_PATH = "${hmUser.xdg.configHome}/vault/vault";
    ZDOTDIR = "${hmUser.xdg.configHome}/zsh";

    CARGO_HOME = "${hmUser.xdg.dataHome}/cargo";
    GNUPGHOME = "${hmUser.xdg.dataHome}/gnupg";
    LESSHISTFILE = "${hmUser.xdg.dataHome}/less/history";
    PASSAGE_DIR = "${hmUser.xdg.dataHome}/passage";
    PASSWORD_STORE_DIR = "${hmUser.xdg.dataHome}/passwords";
    POETRY_HOME = "${hmUser.xdg.dataHome}/poetry";
    UNISON = "${hmUser.xdg.dataHome}/unison";

    EDITOR = "kak";
    VISUAL = "kak";
    PAGER = "kak";

    PYTHONDONTWRITEBYTECODE = "1";
    PYTHONBREAKPOINT = "pudb.set_trace";
    MYPY_CACHE_DIR = "/dev/null";

    UNISONLOCALHOSTNAME = "laptop";
  };

  system.stateVersion = 5;
}
