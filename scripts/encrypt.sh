# Script adapted from https://github.com/mozilla/sops/issues/1137#issuecomment-1312640992

set -e

if test $# -ne 1; then
    echo "Usage: $0 FILE" >&2
    exit 1
fi

if ! test -f "$1"; then
    echo "$0: file $1 does not exist" >&2
    exit 1
fi

key_dir="$(git -C $(dirname $(realpath "$1")) rev-parse --show-toplevel)/secrets/keys"
public_keys=$(ssh-to-age -i <(cat "$key_dir"/*) | tr "\n" "," | head -c -1)
private_keys=$(ssh-to-age -private-key -i <(cat ~/.ssh/* /etc/ssh/*) | tr "\n" "," | head -c -1)
enc_file_name="${1%.json}.enc.json"

if ! git cat-file -e "HEAD:$enc_file_name" &>/dev/null; then
    echo "$0: no previous version found while encrypting $1" >&2
    sops --encrypt --input-type json --output-type json --age "$public_keys" "$1" > "$enc_file_name"
    rm -f "$1"

elif diff \
    <(git cat-file -p "HEAD:$enc_file_name" | SOPS_AGE_KEY="$private_keys" sops --decrypt --input-type json --output-type json /dev/stdin) \
    "$1" >/dev/null; then
    echo "$0: reusing encrypted $1" >&2
    git cat-file -p "HEAD:$enc_file_name" > $enc_file_name
    rm -f "$1"

else
    echo "$0: found changes while encrypting $1" >&2
    sops --encrypt --input-type json --output-type json --age "$public_keys" "$1" > "$enc_file_name"
    rm -f "$1"
fi
