{self}: rec {
  mkNixOSMachine = {
    name,
    system ? "x86_64-linux",
    disabledModules ? [],
    extraModules ? [],
  }:
    self.inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules =
        [
          "${self}/modules/base/all.nix"
          "${self}/modules/base/nixos.nix"
          "${self}/machines/${name}"
          {inherit disabledModules;}
        ]
        ++ extraModules;
      specialArgs = {
        inherit self;
      };
    };

  mkDarwinMachine = {
    name,
    system ? "x86_64-darwin",
    disabledModules ? [],
    extraModules ? [],
  }:
    self.inputs.darwin.lib.darwinSystem {
      inherit system;
      modules =
        [
          "${self}/modules/base/all.nix"
          "${self}/modules/base/darwin.nix"
          "${self}/machines/${name}"
          {inherit disabledModules;}
        ]
        ++ extraModules;
      specialArgs = {
        inherit self;
      };
    };
}
