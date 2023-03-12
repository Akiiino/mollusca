self: super: {
  hydroxide = super.hydroxide.overrideAttrs (old: {
    src = super.fetchFromGitHub {
      owner = "emersion";
      repo = "hydroxide";
      rev = "4cb15fbdf3555e5d1bfc95eece5086fc69aa4f74";
      sha256 = "sha256-YBaimsHRmmh5d98c9x56JIyOOnkZsypxdqlSCG6pVJ4=";
    };
  });
}
