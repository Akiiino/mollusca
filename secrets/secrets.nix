let
  akiiino = builtins.readFile keys/akiiino.pub;
  nautilus = builtins.readFile keys/nautilus.pub;
  pecten = builtins.readFile keys/pecten.pub;
  actinella = builtins.readFile keys/actinella.pub;
  aspersum = builtins.readFile keys/aspersum.pub;
  glabrata = builtins.readFile keys/glabrata.pub;
in
{
  "tailscale.age".publicKeys = [
    akiiino
    nautilus
    pecten
    actinella
    aspersum
    glabrata
  ];
  "actinella-backup.age".publicKeys = [
    akiiino
    actinella
  ];
  "proton-wireguard.age".publicKeys = [
    akiiino
    actinella
  ];
  "minor-secrets.age".publicKeys = [
    akiiino
  ];
  "acme-dns.age".publicKeys = [
    akiiino
    pecten
  ];
}
