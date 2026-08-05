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
    "${self}/users/akiiino/base.nix"
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
    caldavUrl = "http://localhost:${builtins.toString config.services.rustical.settings.http.port}/caldav/";
    caldavUser = "akiiino";
    passwordFile = config.age.secrets.horai-rustical.path;
  };
  age.secrets.horai-rustical.file = secretFile "horai-rustical.age";
}
