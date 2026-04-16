{
  self,
  pkgs,
  minor-secrets,
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
    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
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
    abduco
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
  # systemd.services.sandbox-tmux = {
  #   description = "Persistent Claude Code tmux session";
  #   after = [
  #     "network-online.target"
  #     "tailscaled.service"
  #   ];
  #   wants = [
  #     "network-online.target"
  #   ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "forking";
  #     User = "claude";
  #     ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main ${pkgs.claude-code}/bin/claude --remote-control --dangerously-skip-permissions --model opus";
  #     ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t main";
  #     Restart = "always";
  #     RestartSec = 5;
  #   };
  #   path = [
  #     "/run/wrappers"
  #     "/run/current-system/sw"
  #     "/etc/profiles/per-user/claude"
  #   ];
  # };

  home-manager.users.claude = _: {
    programs = {
      bash = {
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

      git = {
        enable = true;
        userName = "Claude (glabrata)";
        userEmail = "noreply@anthropic.com";
        aliases = {
          mkpatch = "!git diff --quiet && git diff --cached --quiet || { echo 'Error: uncommitted changes exist. Commit or stash them first.'; exit 1; } && git diff @{u} HEAD > ~/claude.patch && echo 'Patch written to ~/claude.patch'";
          syncup = "!git fetch && git diff HEAD..@{u} && git reset --hard @{u}";
        };
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    home.file = {
      "git/.keep".text = "";

      ".claude/CLAUDE.md".text = ''
        # Glabrata — Claude Code Sandbox

        You are running on `glabrata`, a headless NixOS VM dedicated to you (Claude Code).
        No human uses this machine directly — you are the primary operator.
        The human operator (and the person interacting with you) is ${minor-secrets.shortName},
        who manages this machine remotely. Address the operator directly in second person:
        as "you", or by name as ${minor-secrets.shortName} — but always in second person,
        never third person.

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

        ## Declarative configuration

        Most system settings (dotfiles, shell, git config, tools) are managed
        declaratively by home-manager in the mollusca repo. Editing files like
        `~/.gitconfig` or `~/.bashrc` directly won't survive a rebuild — they are
        overwritten on each deployment. **To change any persistent system setting,
        modify the mollusca Nix config** (`machines/glabrata/default.nix`) and
        produce a patch for ${minor-secrets.shortName} to deploy via the collaboration workflow.

        ## Machine configuration

        This machine's NixOS config lives at `https://github.com/Akiiino/mollusca` in the
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
          ${minor-secrets.shortName} pulls changes from glabrata over Tailscale SSH, so repos must
          be at a stable, predictable path (e.g., `~/git/<repo-name>`).
        - direnv + nix-direnv are installed — entering a directory with a `flake.nix`
          and `.envrc` will automatically activate the devshell
        - Git is configured as "Claude (glabrata)" <noreply@anthropic.com>
        - You can clone repos, create branches, and produce patches
        - You do not currently have push access to any remote repos
        - Remember to pull upstream changes before starting or continuing your work

        ## Collaboration workflow

        Use this workflow when making code changes for ${minor-secrets.shortName} to review:

        **Delivering changes:**
        1. Do your work, making one or multiple commits locally as needed (WIP commits are fine).
        2. When ready, run `git mkpatch` — writes all changes vs upstream to `~/claude.patch`.
        3. Tell ${minor-secrets.shortName} the patch is ready. They apply it with:
           `ssh glabrata 'cat ~/claude.patch' | git apply -`
        4. ${minor-secrets.shortName} modifies as needed, commits, and pushes to `origin`.

        **Continuing after ${minor-secrets.shortName} pushes:**
        1. Run `git syncup` — fetches origin, shows what ${minor-secrets.shortName} changed vs your last commit,
           then resets to upstream.
        2. Continue working from the clean upstream state.

        Git aliases (defined in home-manager, available globally):
        - `git mkpatch` — `git diff @{u} HEAD > ~/claude.patch`
        - `git syncup` — `git fetch && git diff HEAD..@{u} && git reset --hard @{u}`
      '';
    };

    home.stateVersion = "23.11";
  };

  networking.hostName = "glabrata";
}
