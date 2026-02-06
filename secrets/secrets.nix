let
  akiiino = builtins.readFile keys/akiiino.pub;
  nautilus = builtins.readFile keys/nautilus.pub;
  mussel = builtins.readFile keys/mussel.pub;
  pecten = builtins.readFile keys/pecten.pub;
  actinella = builtins.readFile keys/actinella.pub;
  entovalva = builtins.readFile keys/entovalva.pub;
in
{
  "tailscale.age".publicKeys = [
    akiiino
    nautilus
    mussel
    pecten
    actinella
  ];
  "AmityTower.age".publicKeys = [
    akiiino
    nautilus
    actinella
    entovalva
  ];
  "actinella-backup.age".publicKeys = [
    akiiino
    actinella
  ];
}
