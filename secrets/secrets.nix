let
  akiiino = builtins.readFile keys/akiiino.pub;
  scallop = builtins.readFile keys/scallop.pub;
in {
  "hetzner.age".publicKeys = [akiiino scallop];
  "nextcloud_root_pass.age".publicKeys = [akiiino scallop];
}
