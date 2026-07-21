{
  modulesPath,
  config,
  self,
  minor-secrets,
  secretFile,
  ...
}:
{
  imports = [
    "${self}/profiles/headless.nix"
    ./hardware-configuration.nix
    ./disko.nix
    "${modulesPath}/profiles/perlless.nix" # not necessary, but it's neat
    ./derper.nix
    ./photos.nix
    ./rustical.nix
  ];

  mollusca = {
    isExitNode = true;
  };
  services.eunomia = {
    enable = true;
    tokenFile = config.age.secrets.eunomia-telegram.path;
    chatId = minor-secrets.telegramId;
  };
  age.secrets.eunomia-telegram.file = secretFile "eunomia-telegram.age";

  networking = {
    hostName = "pecten";
  };
}
