if [ "$1" = "localhost" ]; then
    nixos-rebuild switch --flake ".#$2" --use-remote-sudo
else
    nixos-rebuild switch --flake ".#$2" --fast --target-host "$1" --build-host "$1" --use-remote-sudo
fi
