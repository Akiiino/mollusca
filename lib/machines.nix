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
      { self', inputs', ... }:
      let
        systemBuilder =
          if os == "darwin" then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
      in
      systemBuilder {
        inherit system;
        modules = [
          "${self}/modules/base/all.nix"
          "${self}/machines/${name}"
          { inherit disabledModules; }
        ]
        ++ (if os == "darwin" then [ "${self}/modules/base/darwin.nix" ] else [ ])
        ++ (if os == "nixos" then [ "${self}/modules/base/nixos.nix" ] else [ ])
        ++ extraModules;
        specialArgs = {
          inherit
            self
            self'
            inputs
            inputs'
            ;

          # minor-secrets comes from the `minor-secrets` flake input, which
          # defaults to secrets/minor-secrets.age (age-encrypted). If the
          # input path ends in `.age` we decrypt via mini-agenix; otherwise
          # we import it as a plain Nix file. This lets this flake get evaluated
          # in untrusted environments.
          minor-secrets =
            let
              src = inputs.minor-secrets.outPath;
              isAge = (builtins.match ".*\\.age" (toString src)) != null;
            in
            if isAge then
              builtins.importAge {
                file = src;
                hash = "sha256-F8yJ46McB65dLEEy8RyE+4ZbyG8ZebID0yCBLGk3+EU=";
              }
            else
              import src;
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
