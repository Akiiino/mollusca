# Nearly completely written by Claude, based on https://github.com/NixOS/nixpkgs/blob/7241bcbb/pkgs/by-name/cu/cups-brother-dcpl3550cdw/package.nix

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
in
stdenv.mkDerivation {
  pname = "cups-brother-${model}";
  inherit version;

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf105753/dcpl3520cdwpdrv-${version}.i386.deb";
    hash = "sha256:1vh88s06jqv6fkx74rjc2caizn4kaf8jzspgh0zvncyv9p50w0i6";
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

    # Create architecture-specific symlinks (mimicking postinst)
    ln -s $out/opt/brother/Printers/${model}/lpd/x86_64/br${model}filter \
          $out/opt/brother/Printers/${model}/lpd/br${model}filter
    ln -s $out/opt/brother/Printers/${model}/lpd/x86_64/brprintconf_${model} \
          $out/opt/brother/Printers/${model}/lpd/brprintconf_${model}

    # Create /usr/bin symlink location
    mkdir -p $out/usr/bin
    ln -s $out/opt/brother/Printers/${model}/lpd/brprintconf_${model} \
          $out/usr/bin/brprintconf_${model}

    # Fix the Perl interpreter path and hardcode paths in filter script
    # (The script uses realpath($0) to derive paths, which breaks after wrapProgram
    # moves it to .filter_dcpl3520cdw-wrapped, so we hardcode the values)
    substituteInPlace $out/opt/brother/Printers/${model}/lpd/filter_${model} \
      --replace-fail /usr/bin/perl ${lib.getExe perl} \
      --replace-fail "PRINTER =~" "PRINTER = \"${model}\"; #" \
      --replace-fail "BR_PRT_PATH =~" "BR_PRT_PATH = \"$out/opt/brother/Printers/${model}/\"; #"

    # Fix the lpdwrapper script similarly
    substituteInPlace $out/opt/brother/Printers/${model}/cupswrapper/brother_lpdwrapper_${model} \
      --replace-fail /usr/bin/perl ${lib.getExe perl} \
      --replace-fail "basedir =~ " "basedir = \"$out/opt/brother/Printers/${model}/\"; #" \
      --replace-fail "PRINTER =~ " "PRINTER = \"${model}\"; #" \
      --replace-fail "LPDCONFIGEXE=" "LPDCONFIGEXE=\"$out/usr/bin/brprintconf_\"; #"

    # Patch the ELF binaries to use the correct interpreter and find libstdc++
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
             --set-rpath "${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}" \
             $out/opt/brother/Printers/${model}/lpd/x86_64/br${model}filter

    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
             --set-rpath "${lib.makeLibraryPath [ stdenv.cc.cc.lib ]}" \
             $out/opt/brother/Printers/${model}/lpd/x86_64/brprintconf_${model}

    # Also patch the i686 binaries in case they're needed
    # (Skipping for now - would need pkgsi686Linux)

    # Create CUPS directories and symlinks
    mkdir -p $out/lib/cups/filter $out/share/cups/model

    ln -s $out/opt/brother/Printers/${model}/cupswrapper/brother_lpdwrapper_${model} \
          $out/lib/cups/filter/brother_lpdwrapper_${model}

    ln -s $out/opt/brother/Printers/${model}/cupswrapper/brother_${model}_printer_en.ppd \
          $out/share/cups/model/brother_${model}_printer_en.ppd

    runHook postInstall
  '';

  postFixup = ''
    # Wrap the filter script with required tools in PATH
    wrapProgram $out/opt/brother/Printers/${model}/lpd/filter_${model} \
      --prefix PATH : ${
        lib.makeBinPath [
          ghostscript
          file
          gnused
          gnugrep
          coreutils
          which
        ]
      }

    # Wrap the lpdwrapper with required tools and brprintconf in PATH
    wrapProgram $out/opt/brother/Printers/${model}/cupswrapper/brother_lpdwrapper_${model} \
      --prefix PATH : ${
        lib.makeBinPath [
          gnugrep
          coreutils
        ]
      }:$out/usr/bin

    # The binaries try to access /opt/brother/... directly, so redirect those paths
    wrapProgram $out/usr/bin/brprintconf_${model} \
      --set LD_PRELOAD "${libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS /opt=$out/opt

    wrapProgram $out/opt/brother/Printers/${model}/lpd/br${model}filter \
      --set LD_PRELOAD "${libredirect}/lib/libredirect.so" \
      --set NIX_REDIRECTS /opt=$out/opt
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
    maintainers = [ ];
  };
}
