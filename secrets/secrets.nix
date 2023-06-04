let
  akiiino = builtins.readFile keys/akiiino.pub;
  scallop = builtins.readFile keys/scallop.pub;
in {
  "hetzner.age".publicKeys = [akiiino scallop];
  "nextcloud_root_pass.age".publicKeys = [akiiino scallop];
  "nextcloud_oidc_secret.age".publicKeys = [akiiino scallop];
  "oauth2-proxy.age".publicKeys = [akiiino scallop];
  "oauth2-proxy_keycloak.age".publicKeys = [akiiino scallop];
  "secondbrain_nc_password.age".publicKeys = [akiiino scallop];
  "keycloak_db_pass.age".publicKeys = [akiiino scallop];
  "komga_client_secret.age".publicKeys = [akiiino scallop];
  "minio.age".publicKeys = [akiiino scallop];
  "outline.age".publicKeys = [akiiino scallop];
  "outline_OIDC.age".publicKeys = [akiiino scallop];
  "cifs_users/nextcloud.age".publicKeys = [akiiino scallop];
  "cifs_users/minio.age".publicKeys = [akiiino scallop];
}
