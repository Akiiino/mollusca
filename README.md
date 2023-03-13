# NixOS system configurations for my machines

Contains system configs (think "dotfiles", but as Nix Flakes) for my machines. At the moment contains

- My personal laptop setup, `gastropod`;
- and my new server, `scallop`.

There is also a shell environment I use while modifying these configs, available via `nix develop` or via [`direnv`](https://direnv.net/) (with [`nix-direnv`](https://github.com/nix-community/nix-direnv)).

I'm in the process of migrating services from my old server to use Nix; will add them to these files as I go along.

Secrets management is done via [agenix](https://github.com/ryantm/agenix) (for whole-file secrets) and [sops](https://github.com/mozilla/sops) (for minor things I'd just rather not publish, like emails and URLs).

Applying the configurations (while in the development shell):

- Locally (laptop): ```rebuild localhost gastropod```
- Remotely (from laptop to server): ```rebuild <REMOTE_HOST> scallop```
