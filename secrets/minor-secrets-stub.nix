# Dummy values matching the schema of secrets/minor-secrets.age.
#
# Used when evaluation without decryption is needed. Opt in by
# overriding the `minor-secrets` flake input (see flake.nix).
{
  gitEmail = "git@anna.kowalska.pl";
  derpDomain = "derp.ivan.ivanov.ru";
  personalDomain = "vardenis.pavardenis.lt";
  acmeEmail = "erika@mustermann.de";
  shortName = "John";
  extraText = "";
  mapboxToken = "AA.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.AAAAAAAAAAAAAAAAAAAAAA";
}
