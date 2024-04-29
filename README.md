# NixOS system configurations for my machines

Contains system configs for my machines, as well as the shell environment I use while modifying these configs, available via `nix develop` or via [`direnv`](https://direnv.net/) (with [`nix-direnv`](https://github.com/nix-community/nix-direnv)).

Secrets management is done via [agenix](https://github.com/ryantm/agenix). Minor secret-like things like URLs and emails are just kept in a separate private flake.

## TODOs:
- Unify colorscheme management; `config.mollusca.colorscheme`?
