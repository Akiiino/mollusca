self: super: {
  hydroxide = super.hydroxide.overrideAttrs (old: {
    src = super.fetchFromGitHub {
      owner = "rinkaru";
      repo = "libreddit";
      rev = "c2d9a69e557cef431fa01ae5e96cc20c24aae67f";
      sha256 = "sha256-YBaimsHRmmh5d98c9x56JAyOOnkZsypxdqlSCG6pVJ4=";
    };
  });
}
