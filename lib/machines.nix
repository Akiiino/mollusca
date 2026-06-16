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
      system ? "x86_64-linux",
      disabledModules ? [ ],
      extraModules ? [ ],
    }:
    withSystem system (
      { self', inputs', ... }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${self}/modules/base/all.nix"
          "${self}/machines/${name}"
          { inherit disabledModules; }
        ]
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
}
