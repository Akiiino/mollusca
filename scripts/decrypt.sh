#!/usr/bin/env -S nix run 'github:clhodapp/nix-runner/32a984cfa14e740a34d14fad16fc479dec72bf07' --
#!pure
#!registry nixpkgs github:NixOS/nixpkgs/988cc958c57ce4350ec248d2d53087777f9e1949
#!registry ssh-to-age github:Mic92/ssh-to-age/9610d46f8f3cf0e7535570573d4f4cae50e5e31b
#!package nixpkgs#bash
#!package nixpkgs#coreutils
#!package nixpkgs#nix
#!package nixpkgs#git
#!package nixpkgs#sops
#!package ssh-to-age#ssh-to-age
#!command bash

key_dir="$(git -C $(dirname $(realpath "$0")) rev-parse --show-toplevel)/secrets/keys"
keys=$(ssh-to-age -private-key -i <(cat ~/.ssh/* /etc/ssh/*) | tr "\n" "," | head -c -1)
exec 3<<< "$(cat $1)"
SOPS_AGE_KEY=$keys sops --decrypt --input-type json --output-type json /dev/fd/3
