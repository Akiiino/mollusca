# Dummy values matching the schema of secrets/minor-secrets.age.
#
# Used when evaluation without decryption is needed. Opt in by
# overriding the `minor-secrets` flake input (see flake.nix).
{
  acmeEmail = "erika@mustermann.de";
  gitEmail = "git@anna.kowalska.pl";
  personalDomain = "vardenis.pavardenis.lt";
  name = "Jonathan";
  shortName = "John";
  surname = "Smith";
  derpDomain = "derp.ivan.ivanov.ru";
  mapboxToken = "AA.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA.AAAAAAAAAAAAAAAAAAAAAA";
  extraText = "";
  telegramId = 1;
}
