{
  self,
  pkgs,
  ...
}:
{
  imports = [
    self.inputs.nixos-generators.nixosModules.all-formats
    self.inputs.mollusca-secrets.nixosModules.secrets
    self.inputs.agenix.nixosModules.default
    self.inputs.home-manager.nixosModules.default
    "${self}/modules/remote.nix"
    "${self}/modules/gui.nix"
  ];

  users.mutableUsers = false;
  i18n.defaultLocale = "en_US.UTF-8";
  system = {
    extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
    stateVersion = "23.11";
  };
  programs.zsh.enable = true;
  nix.nixPath = [ "nixpkgs=/run/current-system/nixpkgs" ];
}
