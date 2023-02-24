let
  akiiino = builtins.readFile keys/akiiino.pub;
  scallop = builtins.readFile keys/scallop.pub;
in
{
  "hetzner.age".publicKeys = [ akiiino scallop ];
  "keycloak_db.age".publicKeys = [ akiiino scallop ];
}