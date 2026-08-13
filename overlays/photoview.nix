# photoview 2.4.0 pins github.com/strukturag/libheif at v1.15.1, but nixpkgs
# ships libheif 1.23.1.

_: prev:
let
  inherit (prev) lib;

  # libheif release that typedef'd the enums, i.e. what breaks v1.15.1
  apiBreak = "1.22";
  # first libheif this pin has not been built against
  untested = "1.24";
  # bindings version we substitute in
  bindings = "1.23.1";

  applies = prev.photoview.version == "2.4.0" && lib.versionAtLeast prev.libheif.version apiBreak;

  patched = prev.photoview.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace api/go.sum \
        --replace-fail \
        'libheif v1.15.1 h1:PWMRTk+9HG0a9avvlV597iI0AdHk25zKVV33lSl6a+I=' \
        'libheif v1.23.1 h1:bEjYArYIXfTqWzLYBOM+Wax1yCV5oWMCM3hJRq1aQOQ=' \
        --replace-fail \
        'libheif v1.15.1/go.mod' \
        'libheif v1.23.1/go.mod'
      substituteInPlace api/go.mod \
        --replace-fail 'libheif v1.15.1' 'libheif v1.23.1'
    '';

    vendorHash = "sha256-8wABIYeqV5mHVytAdTk+GyDJTMsRURP19zWbqG667to=";
  });
in
{
  photoview =
    if applies then
      lib.warnIf (lib.versionAtLeast prev.libheif.version untested) ''
        overlays/photoview.nix pins the libheif Go bindings to v${bindings}, but
        nixpkgs now has libheif ${prev.libheif.version}. Re-check the pin.
      '' patched
    else
      lib.warn ''
        overlays/photoview.nix no longer applies (photoview ${prev.photoview.version},
        libheif ${prev.libheif.version}) and is now a no-op. Confirm photoview still
        builds without it, then delete it.
      '' prev.photoview;
}
