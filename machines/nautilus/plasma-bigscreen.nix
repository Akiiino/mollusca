{
  mkKdeDerivation,
  lib,
  fetchFromGitLab,
  pkg-config,
  ki18n,
  kdeclarative,
  kcmutils,
  knotifications,
  kio,
  kwayland,
  kwindowsystem,
  plasma-workspace,
  qtmultimedia,
  bluez-qt,
  qtwebengine,
  plasma-nano,
  plasma-nm,
  milou,
  kscreen,
  kdeconnect-kde,
  qtdeclarative,
}:
mkKdeDerivation {
  pname = "plasma-bigscreen";
  version = "unstable-2025-11-06";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "plasma";
    repo = "plasma-bigscreen";
    rev = "bf471fbf9a03d6e44918d1932d148f17aabe8fff";
    hash = "sha256-rwiL+FWjBz2Lmk1q1V/vUZVtUU7iCrGj+VwS1KwZFjE=";
  };

  extraNativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    ki18n
    kdeclarative
    kcmutils
    knotifications
    kio
    kwayland
    kwindowsystem
    plasma-workspace
    qtmultimedia
    bluez-qt
    qtwebengine
    plasma-nano
    plasma-nm
    milou
    kscreen
    kdeconnect-kde
    qtdeclarative
  ];

  postPatch = ''
    substituteInPlace bin/plasma-bigscreen-wayland.in \
      --replace @KDE_INSTALL_FULL_LIBEXECDIR@ "${plasma-workspace}/libexec"

    # Plasma version numbers are required to match
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set(PROJECT_VERSION "6.4.80")' 'set(PROJECT_VERSION "${plasma-workspace.version}")'

    # Find Qt6QmlPrivate before QCoro to satisfy its link interface dependency
    sed -i '/find_package(QCoro6/i find_package(Qt6 REQUIRED COMPONENTS QmlPrivate)' CMakeLists.txt
  '';

  preFixup = ''
    wrapQtApp $out/bin/plasma-bigscreen-wayland
  '';

  passthru.providedSessions = [
    "plasma-bigscreen-wayland"
  ];

  meta = {
    license = lib.licenses.gpl2Plus;
  };
}
