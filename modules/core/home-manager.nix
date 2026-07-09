{
  self,
  self',
  inputs,
  inputs',
  minor-secrets,
  lib,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        self
        self'
        inputs
        inputs'
        minor-secrets
        ;
      theme = import "${self}/modules/desktop/theming/flexoki.nix" { inherit inputs lib; };
    };
    backupFileExtension = "backup";
  };
}
