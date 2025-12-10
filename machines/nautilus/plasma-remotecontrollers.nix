{
  mkKdeDerivation,
  lib,
  fetchFromGitLab,
  pkg-config,
  # Qt
  qtbase,
  qtdeclarative,
  qtwayland,
  # KF6
  kconfig,
  kcoreaddons,
  kdbusaddons,
  kdeclarative,
  ki18n,
  kcmutils,
  knotifications,
  kpackage,
  kwindowsystem,
  kstatusnotifieritem,
  solid,
  # Plasma
  plasma-workspace,
  libplasma,
  plasma-wayland-protocols,
  # Other
  wayland,
  libevdev,
  # Optional
  libcec,
  xwiimote ? null,
}:
mkKdeDerivation {
  pname = "plasma-remotecontrollers";
  version = "unstable-2025-12-08";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "plasma-bigscreen";
    repo = "plasma-remotecontrollers";
    rev = "206702d5fc9cb01337b4d47cf1afb1a29654a0bc";
    hash = "sha256-LyCcMj9JEV2rApKIb9tOb09MZ9tdUs09CF7qnctoLj0=";
  };

  extraNativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    qtwayland
    kconfig
    kcoreaddons
    kdbusaddons
    kdeclarative
    ki18n
    kcmutils
    knotifications
    kpackage
    kwindowsystem
    kstatusnotifieritem
    solid
    plasma-workspace
    libplasma
    plasma-wayland-protocols
    wayland
    libevdev
    libcec
  ]
  ++ lib.optionals (xwiimote != null) [
    xwiimote
  ];

  meta = {
    description = "Translate events from various input devices to native key presses";
    homepage = "https://invent.kde.org/plasma-bigscreen/plasma-remotecontrollers";
    license = with lib.licenses; [
      gpl2Plus
      lgpl21Plus
    ];
  };
}
