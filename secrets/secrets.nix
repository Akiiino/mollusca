let
  akiiino = builtins.readFile keys/akiiino.pub;
  nautilus = builtins.readFile keys/nautilus.pub;
  gastropod = builtins.readFile keys/gastropod.pub;
  mussel = builtins.readFile keys/mussel.pub;
  pecten = builtins.readFile keys/pecten.pub;
  actinella = builtins.readFile keys/actinella.pub;
in
{
  "tailscale.age".publicKeys = [
    akiiino
    nautilus
    gastropod
    mussel
    pecten
    actinella
  ];
}
