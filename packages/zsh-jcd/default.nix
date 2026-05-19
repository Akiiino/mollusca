{ stdenvNoCC }:
stdenvNoCC.mkDerivation {
  pname = "zsh-jcd";
  version = "0";
  src = ./.;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/share/zsh-jcd jcd.plugin.zsh jcd _jcd _jcd_scan
    runHook postInstall
  '';
}
