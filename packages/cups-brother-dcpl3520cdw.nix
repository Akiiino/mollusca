{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  ghostscript,
  file,
  gnused,
  gnugrep,
  coreutils,
  which,
  perl,
  libredirect,
}:
let
  version = "3.5.1-1";
  model = "dcpl3520cdw";
  interpreter = "${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2";
in
stdenv.mkDerivation {
  pname = "cups-brother-${model}";
  inherit version;
  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf105753/dcpl3520cdwpdrv-${version}.i386.deb";
    hash = "sha256-JgIOyk3bM7s/gO/qL5FTk9gfFRNMZnL6dGZjaYBGCO4=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src $out
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Fix the filter script paths
    substituteInPlace $out/opt/brother/Printers/${model}/lpd/filter_${model} \
      --replace-fail /usr/bin/perl ${lib.getExe perl} \
      --replace-fail "PRINTER =~" "PRINTER = \"${model}\"; #" \
      --replace-fail "BR_PRT_PATH =~" "BR_PRT_PATH = \"$out/opt/brother/Printers/${model}/\"; #"

    # Fix the CUPS wrapper script
    substituteInPlace $out/opt/brother/Printers/${model}/cupswrapper/brother_lpdwrapper_${model} \
      --replace-fail /usr/bin/perl ${lib.getExe perl} \
      --replace-fail '$basedir =~ s/$PRINTER\/cupswrapper\/.*$/$PRINTER\//g;' "\$basedir = \"$out/opt/brother/Printers/${model}/\";" \
      --replace-fail "PRINTER =~ " "PRINTER = \"${model}\"; #"

    # Use the x86_64 versions
    patchelf --set-interpreter ${interpreter} $out/opt/brother/Printers/${model}/lpd/x86_64/br${model}filter
    patchelf --set-interpreter ${interpreter} $out/opt/brother/Printers/${model}/lpd/x86_64/brprintconf_${model}
    
    # Add rpath for the libraries
    patchelf --set-rpath "${lib.makeLibraryPath [stdenv.cc.cc.lib]}" $out/opt/brother/Printers/${model}/lpd/x86_64/br${model}filter
    patchelf --set-rpath "${lib.makeLibraryPath [stdenv.cc.cc.lib]}" $out/opt/brother/Printers/${model}/lpd/x86_64/brprintconf_${model}

    # Create symlinks in expected locations
    mkdir -p $out/usr/bin
    ln -s $out/opt/brother/Printers/${model}/lpd/x86_64/brprintconf_${model} $out/usr/bin/brprintconf_${model}
    
    # Create symlink for the binary filter where the wrapper expects it
    ln -s $out/opt/brother/Printers/${model}/lpd/x86_64/br${model}filter $out/opt/brother/Printers/${model}/lpd/br${model}filter

    mkdir -p $out/lib/cups/filter $out/share/cups/model
    ln -s $out/opt/brother/Printers/${model}/lpd/filter_${model} $out/lib/cups/filter/brlpdwrapper${model}
    ln -s $out/opt/brother/Printers/${model}/cupswrapper/brother_lpdwrapper_${model} $out/lib/cups/filter/brother_lpdwrapper_${model}
    ln -s $out/opt/brother/Printers/${model}/cupswrapper/brother_${model}_printer_en.ppd $out/share/cups/model/brother_${model}_printer_en.ppd

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/opt/brother/Printers/${model}/lpd/filter_${model} \
        --prefix PATH ":" ${
          lib.makeBinPath [
            ghostscript
            file
            gnused
            gnugrep
            coreutils
            which
          ]
        }
    wrapProgram $out/opt/brother/Printers/${model}/cupswrapper/brother_lpdwrapper_${model} \
      --prefix PATH ":" ${
        lib.makeBinPath [
          gnugrep
          coreutils
          gnused
          ghostscript
          file
        ]
      }
    wrapProgram $out/usr/bin/brprintconf_${model} \
      --set LD_PRELOAD "${libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS /opt=$out/opt
    wrapProgram $out/opt/brother/Printers/${model}/lpd/br${model}filter \
      --set LD_PRELOAD "${libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS /opt=$out/opt \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [stdenv.cc.cc.lib]}"
  '';

  meta = {
    homepage = "https://www.brother.com/";
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=eu_ot&lang=en&prod=${model}_eu&os=128";
    description = "Brother DCP-L3520CDW printer driver";
    license = with lib.licenses; [
      unfreeRedistributable
      gpl2Only
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
