let
  akiiino = builtins.readFile keys/akiiino.pub;
  scallop = builtins.readFile keys/scallop.pub;
in {
  "hetzner.age".publicKeys = [akiiino scallop];
  "nextcloud_root_pass.age".publicKeys = [akiiino scallop];
  "oauth2-proxy.age".publicKeys = [akiiino scallop];
  "secondbrain_nc_password.age".publicKeys = [akiiino scallop];
  "keycloak_db_pass.age".publicKeys = [akiiino scallop];
}
