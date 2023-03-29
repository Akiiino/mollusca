decrypt secrets/minor_secrets.enc.json
git add -N secrets/minor_secrets.json

echo "nixos-anywhere"
nix run github:numtide/nixos-anywhere -- "akiiino@$1" --flake ".#$2"
echo "ssh-keygen -R"
ssh-keygen -R "$1"

echo "sleeping for 15 seconds"
sleep 15

echo "keyscan"
ssh-keyscan -t ed25519 "$1" | cut -d" " -f 2- > "secrets/keys/$2.pub"
echo "rekey"
cd secrets/ && agenix -r -i ~/.ssh/akiiino && cd ../

ssh -o "StrictHostKeyChecking=accept-new" "akiiino@$1"

echo "rebuild"
if [ "$1" = "localhost" ]; then
    nixos-rebuild switch --flake ".#$2" --use-remote-sudo
else
    nixos-rebuild switch --flake ".#$2" --fast --target-host "$1" --build-host "$1" --use-remote-sudo
fi

echo "encrypt"
encrypt secrets/minor_secrets.json
git add -N secrets/minor_secrets.json
