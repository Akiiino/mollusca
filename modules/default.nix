{
  imports = [
    ./hardware/8bitdo.nix
    ./hardware/bluetooth.nix
    ./hardware/logitech.nix

    ./services/acme.nix
    ./services/lan-services.nix
    ./services/nas-mounts.nix
    ./services/tv-filter.nix
  ];
}
