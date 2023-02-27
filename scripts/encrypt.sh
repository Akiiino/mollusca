#!/usr/bin/env -S nix run 'github:clhodapp/nix-runner/32a984cfa14e740a34d14fad16fc479dec72bf07' --
#!pure
#!registry nixpkgs github:NixOS/nixpkgs/988cc958c57ce4350ec248d2d53087777f9e1949
#!registry ssh-to-age github:Mic92/ssh-to-age/9610d46f8f3cf0e7535570573d4f4cae50e5e31b
#!package nixpkgs#bash
#!package nixpkgs#coreutils
#!package nixpkgs#git
#!package nixpkgs#sops
#!package nixpkgs#diffutils
#!package ssh-to-age#ssh-to-age
#!command bash

# Script taken from https://github.com/mozilla/sops/issues/1137#issuecomment-1312640992

key_dir="$(git -C $(dirname $(realpath "$0")) rev-parse --show-toplevel)/secrets/keys"
public_keys=$(ssh-to-age -i <(cat "$key_dir"/*) | tr "\n" "," | head -c -1)
private_keys=$(ssh-to-age -private-key -i <(cat ~/.ssh/* /etc/ssh/*) | tr "\n" "," | head -c -1)

if test $# -ne 1; then
  echo "Usage: $0 FILE" >&2
  exit 1
fi

if ! git cat-file -e "HEAD:$1" &>/dev/null; then
  # if git cat-file -e fails, then the file doesn't exist at HEAD, so it's new,
  # meaning we need to encrypt it for the first time
  echo "$0: no previous version found while cleaning $1" >&2
  sops --encrypt --input-type json --output-type json --age "$public_keys" /dev/stdin

elif exec 3< <(echo -n) && diff \
  <(git cat-file -p "HEAD:$1" | SOPS_AGE_KEY="$private_keys" sops --decrypt --input-type json --output-type json /dev/stdin) \
  <(cat /dev/stdin | tee /dev/fd/3) >/dev/null; then
  # if there's no difference between the decrypted version of the file at HEAD
  # and the new contents, then we re-use the previous version to prevent
  # unnecessary file updates
  echo "$0: no changes found while cleaning $1" >&2
  git cat-file -p "HEAD:$1"

else
  # if there is a difference then we re-encrypt it from fd 3, where we
  # duplicated stdin to
  echo "$0: found changes while cleaning $1" >&2
  sops --encrypt --input-type json --output-type json --age "$public_keys" /dev/fd/3
fi
