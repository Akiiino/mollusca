self: super: {
  libreddit = super.libreddit.overrideAttrs (old: rec {
    version = "0.30.0";
    src = super.fetchFromGitHub {
      owner = "rinkaru";
      repo = "libreddit";
      rev = "c2d9a69e557cef431fa01ae5e96cc20c24aae67f";
      sha256 = "sha256-N51CaevwyKi0F10/ocU20xMwOiL5Ac4sdEIW2OnPCr0=";
    };
    cargoDeps = old.cargoDeps.overrideAttrs (_: {
      name = "libreddit-0.30.0-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-7nbHWN+8jKIQITyGhi8c/oHWTIWh2KrmsKuj7FT5EDA=";
    });
  });
}
