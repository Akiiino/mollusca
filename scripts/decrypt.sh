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
SOPS_AGE_KEY=$(ssh-to-age -private-key -i <(cat ~/.ssh/* /etc/ssh/*) | tr "\n" "," | head -c -1) sops --decrypt "$1" > "${1%.enc.json}.json"
rm -f "$1"
