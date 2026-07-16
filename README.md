# mollusca

NixOS flake with configs for my tiny fleet. Also has a devshell with the tools I use to
work on it, available via `nix develop`, or automatically with
[direnv](https://direnv.net/) and
[nix-direnv](https://github.com/nix-community/nix-direnv).

| Machine     | Hardware             | Role                                      |
| ---         | ---                  | ---                                       |
| `aspersum`  | Framework 13         | daily-driver laptop                       |
| `nautilus`  | AMD + NVIDIA desktop | gaming desktop                            |
| `actinella` | Framework mainboard  | home server: media, smart home, etc.      |
| `pecten`    | Hetzner VPS          | Tailscale exit node, self-hosted services |
| `glabrata`  | Hetzner VPS          | cloud sandbox                             |

## Layout

```
flake.nix   inputs; calls lib.mkNixOSMachines; devshell, formatter, lint checks
lib/        mostly just mkMachine: assembles a system from modules/core + machines/<name>
machines/   one directory per machine; each machine has a default.nix,
            hardware-configuration.nix, disko.nix, and optionally machine-specific files
modules/
  core/     imported by every machine: nix settings, home-manager wiring, remote access
  desktop/  GUI: Niri, Plasma, theming
  hardware/ opt-in peripheral support (bluetooth, logitech, 8bitdo)
  services/ reusable service modules (acme, lan-services, nas-mounts)
  home/     home-manager modules; mostly app configs
overlays/   nixpkgs overlays: customized packages and upstream patches/pins
packages/   standalone derivations
profiles/   layers machines opt into: headless, desktop{-niri,-plasma,}
secrets/    agenix-encrypted secrets, host/user public keys
users/      per-user home-manager config, split into base/desktop/personal layers
```

## Machine anatomy

`flake.nix` lists the machines; `lib/default.nix` (`mkMachine`) turns each into
a `nixosSystem` that imports `modules/core` and `machines/<name>`. Everything
else is pulled in by the machine's `default.nix`. All machines import a profile
(headless/desktop/desktop-niri/etc.) for base configuration, then layer evrything
else on top.

### Profiles
- `headless`: enable remote access, enable Tailscale
- `desktop`: also enable desktop hardware support (Logitech, 8BitDo, etc.) and
  desktop niceties: fonts, quiet boot with pretty Plymouth, networkmanager, etc.
- `desktop-plasma`: `desktop` + KDE Plasma.
- `desktop-niri`: `desktop` + Niri and a bunch of necessities: Swaylock, Thunar,
  GVFS, and everything else needed for a usable desktop machine.

### User layers
Similarly, my user config is split into layers:
- `base.nix` is for all machines with that user and defines the shell environment:
  ZSH, Git, Kakoune, etc.
- `desktop.nix` is for the GUI machines: installs a bunch of graphical apps.
- `personal.nix` is for the main daily driver(s?): stuff I need to log into to use,
  basically.

## Theming

`modules/desktop/theming/flexoki.nix` parses the
[Flexoki](https://stephango.com/flexoki) palette from the upstream flake input
and exposes it as the `theme` module argument (wired up in
`modules/core/home-manager.nix`). Various consumers (Niri, Kitty, Starship, Kakoune,
the wallpaper, etc.) derive their colors from it.
Themed assets (wallpaper, so far) are kept as neutral, recolorable sources and tinted
at build time, so the whole colorscheme stays swappable in one place.

## Secrets

- proper run-time secrets - [agenix](https://github.com/ryantm/agenix) `.age`
  files, decrypted on the target machine at activation using its host key.
- minor secrets needed at eval (IDs, hostnames, names, etc.) -
  [mini-agenix](https://github.com/akiiino/mini-agenix)'s `builtins.importAge`
  inside a `tryEval`; on machines without an age identity it falls back to
  `secrets/minor-secrets-stub.nix`, so the flake always evaluates.
