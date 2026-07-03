{ inputs }:
final: prev:
let
  tomlFormat = final.formats.toml { };

  providerConfig = {
    desktopapplications = {
      window_integration = true;
    };
    clipboard.hide_from_providerlist = true;
    windows.hide_from_providerlist = true;
    symbols.hide_from_providerlist = true;
  };

  configDir = final.linkFarm "elephant-config" (
    final.lib.mapAttrsToList (provider: settings: {
      name = "${provider}.toml";
      path = tomlFormat.generate "elephant-${provider}.toml" settings;
    }) providerConfig
  );

  elephant = prev.elephant.override {
    enabledProviders = [
      "calc"
      "clipboard"
      "desktopapplications"
      "files"
      "menus"
      "niriactions"
      "nirisessions"
      "providerlist"
      "symbols"
      "unicode"
      "windows"
    ];
  };
in
{
  mollusca = (prev.mollusca or { }) // {
    elephant = inputs.wrapper-manager.lib.wrapWith final {
      basePackage = elephant;
      prependFlags = [
        "--config"
        configDir
      ];
    };
  };
}
