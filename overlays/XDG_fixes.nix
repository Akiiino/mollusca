# Replaces apps with wrapped versions that respect XDG.

final: prev: {
  android-tools-xdg = prev.android-tools.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ final.makeWrapper ];
    postFixup = (oldAttrs.postFixup or "") + ''
      wrapProgram $out/bin/adb \
        --run 'export HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/android"'
    '';
  });
  wget-xdg = prev.wget.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ final.makeWrapper ];
    postFixup = (oldAttrs.postFixup or "") + ''
      wrapProgram $out/bin/wget \
        --add-flag '--hsts-file="''${XDG_DATA_HOME:-$HOME/.local/share}/wget-hsts"'
    '';
  });
}
