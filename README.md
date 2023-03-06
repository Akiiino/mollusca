# NixOS system configurations for my machines

Contains system configs (think "dotfiles", but as Nix Flakes) for my machines. At the moment contains

- My personal laptop setup, `gastropod`;
- and my new server, `scallop`.

I'm in the process of migrating services from my old server to use Nix; will add them to these files as I go along.

Secrets management is done via [agenix](https://github.com/ryantm/agenix) (for whole-file secrets) and [agebox](https://github.com/slok/agebox) (for minor things I'd just rather not publish, like emails and URLs).

Applying the configurations:

- Locally (laptop): ```sudo nixos-rebuild switch --flake github:akiiino/mollusca#gastropod```
- Remotely (from laptop to server): ```nixos-rebuild switch --flake github:akiiino/mollusca#scallop --fast --target-host <REMOTE_HOST> --build-host <REMOTE_HOST> --use-remote-sudo```
