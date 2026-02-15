let
  akiiino = builtins.readFile keys/akiiino.pub;
  nautilus = builtins.readFile keys/nautilus.pub;
  pecten = builtins.readFile keys/pecten.pub;
  actinella = builtins.readFile keys/actinella.pub;
in
{
  "tailscale.age".publicKeys = [
    akiiino
    nautilus
    pecten
    actinella
  ];
  "actinella-backup.age".publicKeys = [
    akiiino
    actinella
  ];
  "proton-wireguard.age".publicKeys = [
    akiiino
    actinella
  ];
}
