{
  self,
  pkgs,
  ...
}: {
  imports = [
    self.inputs.mollusca-secrets.darwinModules.secrets
    self.inputs.agenix.darwinModules.default
    self.inputs.home-manager.darwinModules.default
    self.inputs.mac-app-util.darwinModules.default
  ];

  environment.extraSetup = ''
    ln -sv ${pkgs.path} $out/nixpkgs
  '';
  nix.nixPath = pkgs.lib.mkForce ["nixpkgs=/run/current-system/sw/nixpkgs"];
}
