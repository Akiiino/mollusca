{
  self,
  withSystem,
  ...
}: rec {
  mkNixOSMachine = {
    name,
    system ? "x86_64-linux",
    disabledModules ? [],
    extraModules ? [],
    pkgs ? self.inputs.nixpkgs,
  }:
    withSystem system ({inputs', ...}:
      pkgs.lib.nixosSystem {
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
          inherit self inputs';
        };
      });

  mkNixOSMachines = machines:
    builtins.mapAttrs
    (
      name: config:
        self.lib.mkNixOSMachine (
          {
            inherit name;
          }
          // config
        )
    )
    machines;

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

  mkDarwinMachines = machines:
    builtins.mapAttrs
    (
      name: config:
        self.lib.mkDarwinMachine (
          {
            inherit name;
          }
          // config
        )
    )
    machines;
}
