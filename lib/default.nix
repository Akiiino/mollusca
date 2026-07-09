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
      system ? "x86_64-linux",
      disabledModules ? [ ],
      extraModules ? [ ],
    }:
    withSystem system (
      { self', inputs', ... }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${self}/modules/core"
          "${self}/machines/${name}"
          { inherit disabledModules; }
        ]
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
                  hash = "sha256-WjPIl8eYQIRnTqXQnuEdgNxM/ptVrgSQaRkciDcVLCo=";
                }
              );
            in
            if attempt.success then attempt.value else import "${self}/secrets/minor-secrets-stub.nix";
        };
      }
    );

  mkNixOSMachines = builtins.mapAttrs (name: config: mkMachine ({ inherit name; } // config));
}
