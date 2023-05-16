{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    jq
    shellcheck
    proselint
    tmux
    coreutils
    moreutils
    exa
    fzf
    htop
    wget
    rsync
    curl
    git
    kakoune
    kak-lsp
    openssl
    readline
    xz
    zlib
    sqlite
    skhd
    (writeShellScriptBin "write_pom" ''
      last_pom=$(tail -n 3 ~/poms)
      reply=$(osascript -e "display dialog \"$last_pom\" default answer \"\"" -e "text returned of the result")
      if [ -n "$reply" ]; then
          date=$(date '+%m-%d %H:%M')
          printf "%s: %s\n" "$date" "$reply" >> ~/poms
      fi
    '')
    (writeShellScriptBin "write_pom_bad" (builtins.readFile "${self}/scripts/write_pom"))

    python310
    poetry
    (unison.override {enableX11 = false;})

    iina
    slack
    vault
    # self.inputs.gitsh.packages.x86_64-darwin.gitsh
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "slack"
    ];

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
      {
        name = "dimentium/autoraise/autoraise";
        args = ["with-dexperimental_focus_first"];
      }
      "pure"
      "rust"
      "pass"
      "thoughtbot/formulae/gitsh"
    ];
    casks = [
      "firefox"
      "jupyterlab"
      "keka"
      "kitty"
      "logitech-options"
      "microsoft-teams"
      "monitorcontrol"
      "notion"
      "obsidian"
      "rectangle-pro"
      "spotify"
      "zotero"
    ];
    taps = [
      "dimentium/autoraise"
      "thoughtbot/formulae"
    ];
  };

  nix.extraOptions = ''
    bash-prompt-prefix = (nix:$name)\040
    extra-nix-path = nixpkgs=flake:nixpkgs
    experimental-features = nix-command flakes
    build-users-group = nixbld
  '';
  services.nix-daemon.enable = true;

  programs.zsh = {
    enable = true;
    promptInit = "autoload -U promptinit; promptinit; prompt pure";
    enableSyntaxHighlighting = true;
    enableFzfCompletion = true;
    enableFzfHistory = true;
    enableFzfGit = true;
  };

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
      cmd + alt + ctrl - p : write_pom
    '';
  };

  system.stateVersion = 4;
}
