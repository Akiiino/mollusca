{
  self,
  pkgs,
  lib,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    self.inputs.impermanence.nixosModules.impermanence
    # "${modulesPath}/profiles/perlless.nix"
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
  };

  system.tools = {
    nixos-rebuild.enable = false;
    nixos-install.enable = false;
  };


  # Persistent volume — survives nixos-anywhere reinstalls.
  # Deliberately NOT in disko.nix so it won't be reformatted on reinstall.
  fileSystems."/mnt/persist" = {
    device = "/dev/disk/by-id/scsi-0HC_Volume_105394318";
    fsType = "btrfs";
    options = [
      "discard"
      "nofail"
      "compress=zstd"
    ];
    neededForBoot = true;
  };

  # impermanence bind-mounts paths from /mnt/persist into their real locations.
  environment.persistence."/mnt/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/tailscale"
    ];
    users.claude = {
      directories = [
        ".claude/projects/-/memory"
      ];
      files = [
        ".claude/.credentials.json"
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    claude-code
    tmux
    git
    curl
    jq
    ripgrep
    fd
    tree
    htop
    # Additional tools for a productive agent environment
    python3
    file
    less
    wget
    unzip
    gnumake
    gcc
    openssh
    diffutils
    patch
    which
  ];

  # The claude user is the dedicated Claude Code operator on this machine.
  users.users.claude = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
    ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
    ];
  };

  # Persistent Claude Code tmux session for the claude user.
  systemd.services.sandbox-tmux = {
    description = "Persistent Claude Code tmux session";
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      User = "claude";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main ${pkgs.claude-code}/bin/claude --remote-control --dangerously-skip-permissions --model opus";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t main";
      Restart = "always";
      RestartSec = 5;
    };
    path = [
      "/run/wrappers"
      "/run/current-system/sw"
      "/etc/profiles/per-user/claude"
    ];
  };

  home-manager.users.claude =
    { ... }:
    {
      programs.bash = {
        enable = true;
        historySize = 50000;
        historyFileSize = 100000;
        historyControl = [
          "ignoredups"
          "ignorespace"
        ];
        shellAliases = {
          ll = "ls -lah";
          la = "ls -A";
          gs = "git status";
          gd = "git diff";
          gl = "git log --oneline -20";
        };
        initExtra = ''
          # Show working directory and git branch in prompt
          __git_branch() {
            git branch --show-current 2>/dev/null
          }
          PS1='\[\e[1;34m\]\w\[\e[0m\]$(__git_branch | sed "s/.*/ (\0)/") \$ '
        '';
      };

      programs.git = {
        enable = true;
        userName = "Claude (glabrata)";
        userEmail = "noreply@anthropic.com";
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      home.file."git/.keep".text = "";

      home.file.".claude/CLAUDE.md".text = ''
        # Glabrata — Claude Code Sandbox

        You are running on `glabrata`, a headless NixOS VM dedicated to you (Claude Code).
        No human uses this machine directly — you are the primary operator.
        The human operator (and the person interacting with you) is Akiiino,
        who manages this machine remotely.

        ## System overview

        - **OS**: NixOS 25.11 (declarative, immutable system config)
        - **User**: `claude` (wheel group, passwordless sudo)
        - **Session**: You run inside a tmux session (`main`) managed by systemd
        - **Network**: Tailscale VPN; internet access available
        - **Resources**: ~8 GiB RAM, ~76 GiB disk (mostly free)
        - **Auth**: OAuth credentials at `~/.claude/.credentials.json` (bind-mounted from persistent volume)

        ## Package management

        This is NixOS — **do not use `apt`, `brew`, `pip install --global`**, etc.

        - One-off command: `nix run nixpkgs#<package>` (e.g., `nix run nixpkgs#cowsay -- hello`)
        - Add to current shell: `nix shell nixpkgs#<package>`
        - Multiple packages: `nix shell nixpkgs#foo nixpkgs#bar`
        - Search for packages: `nix search nixpkgs <query>`

        The nixpkgs registry is pinned to a specific revision, so these commands
        are fast and deterministic after first use.

        Pre-installed tools: git, curl, jq, ripgrep, fd, tree, htop, python3,
        gcc, gnumake, less, wget, unzip, openssh, file, diffutils, patch, which.

        ## Permissions and safety

        You have passwordless sudo. This is an isolated sandbox — there is nothing
        here you can break that matters. The machine can be wiped and reinstalled
        at any time via `nixos-anywhere`.

        However: `nixos-rebuild` is **disabled**. You cannot change the system
        configuration from this machine.

        This file (`CLAUDE.md`) is managed by home-manager and is **read-only**
        on glabrata. To change it, the mollusca repo must be updated and
        redeployed.

        ## Machine configuration

        This machine's NixOS config lives at `github.com/Akiiino/mollusca` in the
        `machines/glabrata/` directory. Key files:
        - `default.nix` — main config (users, services, packages, home-manager)
        - `disko.nix` — disk partitioning layout
        - `hardware-configuration.nix` — QEMU guest hardware

        Shared modules are in `modules/mollusca/` (remote.nix, gui.nix, etc.)
        and `modules/base/` (all.nix, nixos.nix).

        ## Persistence across reinstalls

        The machine may be wiped and rebuilt at any time. What survives:
        - **Persistent volume**: `/mnt/persist` mirrors the real filesystem layout.
          Paths on the volume are bind-mounted to their real locations at boot.
          Currently persisted: memories (`~/.claude/projects/-/memory/`) and
          OAuth credentials (`~/.claude/.credentials.json`).
        - **System config**: Everything in the mollusca repo
        - **Nothing else**: Treat local state as ephemeral

        ## Working with projects

        - **Repo location**: Always clone and work on repos in `~/git/`.
          Akiiino pulls changes from glabrata over Tailscale SSH, so repos must
          be at a stable, predictable path (e.g., `~/git/<repo-name>`).
        - direnv + nix-direnv are installed — entering a directory with a `flake.nix`
          and `.envrc` will automatically activate the devshell
        - Git is configured as "Claude (glabrata)" <noreply@anthropic.com>
        - You can clone repos, create branches, and produce patches
        - You do not currently have push access to any remote repos
        - Remember to pull upstream changes before starting or continuing your work
      '';

      home.stateVersion = "23.11";
    };

  # Keep the builder user exactly as the other machines define it
  # (via mollusca.isRemote in remote.nix). No glabrata-specific overrides.

  networking.hostName = "glabrata";
}
