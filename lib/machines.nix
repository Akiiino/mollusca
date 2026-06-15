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

          # minor-secrets is age-encrypted (secrets/minor-secrets.age), decrypted
          # at eval time via mini-agenix's importAge. On a machine without an age
          # identity (e.g. the glabrata sandbox) importAge raises an error, so we
          # fall back to the stub
          minor-secrets =
            let
              attempt = builtins.tryEval (
                builtins.importAge {
                  file = "${self}/secrets/minor-secrets.age";
                  hash = "sha256-HYaQNwKM5cBHr/ZamVt0QXDkNuJj0fugTqKT0nRQlAE=";
                }
              );
            in
            if attempt.success then attempt.value else import "${self}/secrets/minor-secrets-stub.nix";
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
