decrypt secrets/minor_secrets.enc.json
git add -N secrets/minor_secrets.json

if [ "$1" = "localhost" ]; then
    nixos-rebuild switch --flake ".#$2"
else
    nixos-rebuild switch --flake ".#$2" --fast --target-host "$1" --build-host "$1" --use-remote-sudo
fi

encrypt secrets/minor_secrets.json
git add -N secrets/minor_secrets.json
