{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
  imports = [
    self.inputs.arkenfox.hmModules.arkenfox
  ];
  programs.firefox = {
    enable = true;
    policies = {
      # doesn't work on darwin ;(
      DisableFirefoxAccounts = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      # TODO: switch to custom?
      # DNSOverHTTPS = {
      #   Enabled = false;
      # };
      NetworkPrediction = false;
    };
    arkenfox = {
      enable = true;
      version = "133.0";
    };
    profiles.akiiino = {
      id = 0;
      name = "akiiino";
      isDefault = true;
      extensions.packages = with self.inputs.firefox-addons.packages."${pkgs.hostPlatform.system}"; [
        # TODO: save extension configs
        keepass-helper
        # tree-style-tab
        sidebery
        ublock-origin
        vimium
      ];
      userChrome = ''
        #main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar > .toolbar-items {
          opacity: 0;
          pointer-events: none;
        }

        #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
            visibility: collapse !important;
        }

        #sidebar-box[sidebarcommand="_3c078156-979c-498b-8990-85f7987dd929_-sidebar-action"] #sidebar-header {
          display: none;
        }
      '';
      containersForce = true;
      containers = {
        "Personal" = {
          id = 1;
          color = "blue";
          icon = "fingerprint";
        };
        "Work" = {
          id = 2;
          color = "orange";
          icon = "briefcase";
        };
        "Banking" = {
          id = 3;
          color = "green";
          icon = "dollar";
        };
        "Shopping" = {
          id = 4;
          color = "pink";
          icon = "cart";
        };
        "Test" = {
          id = 5;
          color = "red";
          icon = "pet";
        };
      };
      arkenfox = {
        enable = true;
        enableAllSections = true;
        "0100"."0102"."browser.startup.page".value = 3; # resume previous session
        "1000"."1003"."browser.sessionstore.privacy_level".value = 0; # don't delete data on close
        "2600"."2651"."browser.download.useDownloadDir".value = true; # don't ask for downloads
        "2600"."2652"."browser.download.alwaysOpenPanel".value = true; # show download panel
        "2600"."2654"."browser.download.always_ask_before_handling_new_types".value = false; # don't ask for downloads
        "2800"."2811" = {
          "privacy.clearOnShutdown.cache".value = true;
          "privacy.clearOnShutdown_v2.cache".value = true;
          "privacy.clearOnShutdown.downloads".value = true;
          "privacy.clearOnShutdown.formdata".value = true;
          "privacy.clearOnShutdown.history".value = false;
          "privacy.clearOnShutdown_v2.historyFormDataAndDownloads".value = false;
          "privacy.clearOnShutdown.siteSettings".value = false;
          "privacy.clearOnShutdown_v2.siteSettings".value = false;
        };
        "2800"."2815" = {
          "privacy.clearOnShutdown.cookies".value = false;
          "privacy.clearOnShutdown.offlineApps".value = false;
          "privacy.clearOnShutdown.sessions".value = false;
          "privacy.clearOnShutdown_v2.cookiesAndStorage".value = false;
        };
        "2800"."2840"."privacy.sanitize.timeSpan".value = "1";
        "5000"."5003"."signon.rememberSignons" = {
          enable = true;
          value = false;
        };
        "5000"."5017" = {
          "extensions.formautofill.addresses.enabled" = {
            enable = true;
            value = false;
          };
          "extensions.formautofill.creditCards.enabled" = {
            enable = true;
            value = false;
          };
        };
        "5000"."5021"."keyword.enabled" = {
          enable = true;
          value = false;
        };
      };
      settings = {
        # https://ffprofile.com/
        "app.update.auto" = false;
        # "beacon.enabled" = false;  # reenable?
        "browser.disableResetPrompt" = true;
        "browser.fixup.alternate.enabled" = false;
        "browser.selfsupport.url" = "";
        "browser.shell.checkDefaultBrowser" = false;
        "browser.urlbar.groupLabels.enabled" = false;
        "browser.urlbar.trimURLs" = false;
        "dom.private-attribution.submission.enabled" = false;
        "experiments.activeExperiment" = false;
        "experiments.enabled" = false;
        "experiments.manifest.uri" = "";
        "experiments.supported" = false;
        "extensions.getAddons.cache.enabled" = false;
        "extensions.pocket.enabled" = false;
        "extensions.shield-recipe-client.api_url" = "";
        "extensions.shield-recipe-client.enabled" = false;
        "media.autoplay.default" = 0;
        "media.autoplay.enabled" = true;
        "media.eme.enabled" = false;
        "browser.eme.ui.enabled" = false;
        "media.gmp-widevinecdm.enabled" = false;
        "network.allow-experiments" = false;
        "security.ssl.disable_session_identifiers" = true;
        # "webgl.disabled" = true;  # breaks stuff
        # "webgl.renderer-string-override" = " ";
        # "webgl.vendor-string-override" = " ";

        # Manual
        # don't show history in suggestions
        "browser.urlbar.suggest.history" = false;

        "privacy.annotate_channels.strict_list.enabled" = true; # strict tracker blocking; disable if causes problems?

        "privacy.history.custom" = true; # not needed anymore?

        # misc
        "intl.regional_prefs.use_os_locales" = true; # use OS locale
        "layout.spellcheckDefault" = 0; # no spellcheck
        "browser.ml.chat.enabled" = false; # no AI chat
        "browser.translations.enable" = false; # no translations
        "browser.translations.automaticallyPopup" = false; # no translations
        "browser.translations.panelShown" = true; # no translations
        "extensions.screenshots.disabled" = true; # no screenshots
        "identity.fxaccounts.enabled" = false; # no Firefox Sync

        "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # enable userChrome.css
        "media.videocontrols.picture-in-picture.video-toggle.has-used" = true; # disable PiP reminder
      };
      search = {
        force = true;
        engines = {
          "Nixpkgs" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "NixOS Wiki" = {
            urls = [ { template = "https://wiki.nixos.org/index.php?search={searchTerms}"; } ];
            iconUpdateURL = "https://wiki.nixos.org/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = [ "@nw" ];
          };

          "Bing".metaData.hidden = true;
          "Google".metaData.hidden = true;
          "Ecosia".metaData.hidden = true;
          "Wikipedia (en)".metaData.hidden = true;
        };
      };
    };
  };
}
