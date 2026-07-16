# Dummy values matching the schema of secrets/minor-secrets.age.
#
# lib/default.nix decrypts minor-secrets.age at eval time (mini-agenix's
# builtins.importAge) inside a tryEval; on machines without an age identity
# that fails and this stub is imported instead, so the flake still evaluates.
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
