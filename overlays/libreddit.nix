self: super: {
  libreddit = super.libreddit.overrideAttrs (old: rec {
    version = "0.30.0";
    src = super.fetchFromGitHub {
      owner = "rinkaru";
      repo = "libreddit";
      rev = "b1d090bd126ff0f15e34353f099393ce69dade98";
      sha256 = "sha256-k5Mlw0aOPgCtpxbkAaUC+ENGS73YjcA+w5D1vS2RxGA=";
    };
    cargoDeps = old.cargoDeps.overrideAttrs (_: {
      name = "libreddit-0.30.0-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-7nbHWN+8jKIQITyGhi8c/oHWTIWh2KrmsKuj7FT5EDA=";
    });
  });
}
