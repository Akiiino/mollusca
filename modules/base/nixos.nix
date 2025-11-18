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

    "${self}/modules/mollusca"
  ];

  users.mutableUsers = false;
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = "all";
    extraLocaleSettings = {
      LC_NUMERIC="en_IE.UTF-8";
      LC_TIME="en_IE.UTF-8";
      LC_MONETARY="de_DE.UTF-8";
      LC_PAPER="en_IE.UTF-8";
      LC_MEASUREMENT="en_IE.UTF-8";
    };
  };
  system = {
    extraSystemBuilderCmds = ''
      ln -sv ${pkgs.path} $out/nixpkgs
    '';
    stateVersion = "23.11";
  };
  programs = {
    nix-ld.enable = true;
  };
  nix.nixPath = [ "nixpkgs=/run/current-system/nixpkgs" ];
}
