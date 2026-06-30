final: prev: {
  mollusca = (prev.mollusca or { }) // {
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
  };
}
