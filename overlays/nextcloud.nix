self: super: {
  nextcloud26 = super.nextcloud26.overrideAttrs (old: rec {
    version = "26.0.1";
    sha256 = "sha256-b5xqEkjXyK9K1HPXOkJWX2rautRTHFz6V7w0l7K2T0g=";
    src = builtins.fetchurl {
      url = "https://download.nextcloud.com/server/releases/${old.pname}-${version}.tar.bz2";
      inherit sha256;
    };
  });
}
