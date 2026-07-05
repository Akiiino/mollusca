# Flexoki GTK theme (an adw-gtk3 fork, gtk3 + gtk4/libadwaita) built from the
# kepano/flexoki flake input, since nixpkgs has no Flexoki package. Exposed as
# pkgs.mollusca.flexoki-gtk; consumed by the theming home-manager module.
{ inputs }:
final: prev: {
  mollusca = (prev.mollusca or { }) // {
    flexoki-gtk = final.stdenvNoCC.mkDerivation {
      pname = "flexoki-gtk-theme";
      version = "0-unstable-${inputs.flexoki.shortRev or "dirty"}";
      src = "${inputs.flexoki}/gtk";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        mkdir -p "$out/share/themes/flexoki"
        cp -r ./. "$out/share/themes/flexoki/"
        runHook postInstall
      '';
      meta = {
        description = "Flexoki GTK theme (adw-gtk3 fork)";
        homepage = "https://github.com/kepano/flexoki";
        license = final.lib.licenses.mit;
        platforms = final.lib.platforms.linux;
      };
    };
  };
}
