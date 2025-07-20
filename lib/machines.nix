{
  self,
  inputs,
  withSystem,
  ...
}:
rec {
  mkMachine =
    {
      name,
      os ? "nixos",
      system ? if os == "darwin" then "aarch64-darwin" else "x86_64-linux",
      disabledModules ? [ ],
      extraModules ? [ ],
    }:
    withSystem system (
      { inputs', ... }:
      let
        systemBuilder =
          if os == "darwin" then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
      in
      systemBuilder {
        inherit system;
        modules =
          [
            "${self}/modules/base/all.nix"
            "${self}/machines/${name}"
            { inherit disabledModules; }
          ]
          ++ (if os == "darwin" then [ "${self}/modules/base/darwin.nix" ] else [ ])
          ++ (if os == "nixos" then [ "${self}/modules/base/nixos.nix" ] else [ ])
          ++ extraModules;
        specialArgs = {
          inherit self inputs inputs';
        };
      }
    );

  mkNixOSMachines = builtins.mapAttrs (
    name: config:
    mkMachine (
      {
        inherit name;
        os = "nixos";
      }
      // config
    )
  );

  mkDarwinMachines = builtins.mapAttrs (
    name: config:
    mkMachine (
      {
        os = "darwin";
        inherit name;
      }
      // config
    )
  );
}
