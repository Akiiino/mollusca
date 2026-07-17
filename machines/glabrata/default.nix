{
  self,
  pkgs,
  minor-secrets,
  ...
}:
let
  # Wrap claude-code so it always loads our home-manager-managed MCP config
  # without touching the mutable ~/.claude.json or ~/.claude/settings.json.
  mcpJson = pkgs.writeText "claude-mcp.json" (
    builtins.toJSON {
      mcpServers = {
        nixos = {
          type = "stdio";
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        };
      };
    }
  );
  claude-code-wrapped = pkgs.symlinkJoin {
    name = "claude-code-wrapped-${pkgs.claude-code.version or "0"}";
    paths = [ pkgs.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --add-flags "--mcp-config ${mcpJson}" \
        --set ENABLE_TOOL_SEARCH false
    '';
    inherit (pkgs.claude-code) meta;
  };

  # Generic "diff working tree against freshly-fetched upstream" patch builder.
  # Not git- or repo-specific: works in any clone with an upstream. Captures
  # tracked AND untracked changes (with binary content), requires no commit, and
  # mutates nothing — `git fetch` only moves remote-tracking refs, and the diff
  # is computed in a throwaway index so the real index/worktree are untouched.
  mkpatch = pkgs.writeShellApplication {
    name = "mkpatch";
    runtimeInputs = [
      pkgs.git
      pkgs.coreutils
    ];
    text = ''
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "mkpatch: not inside a git repository" >&2
        exit 1
      fi
      git fetch --quiet || echo "mkpatch: warning: fetch failed; using cached refs" >&2
      upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
      if [ -z "$upstream" ]; then
        upstream=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || true)
      fi
      if [ -z "$upstream" ]; then
        echo "mkpatch: no upstream branch found (set one or add an 'origin' remote)" >&2
        exit 1
      fi
      out="$HOME/claude.patch"
      tmpindex=$(mktemp)
      trap 'rm -f "$tmpindex"' EXIT
      GIT_INDEX_FILE="$tmpindex" git read-tree "$upstream"
      GIT_INDEX_FILE="$tmpindex" git add -A
      GIT_INDEX_FILE="$tmpindex" git diff --cached --binary "$upstream" >"$out"
      echo "mkpatch: wrote $out ($(grep -c '^' "$out") lines, vs $upstream)"
    '';
  };

  # PostToolUse hook (Write|Edit|Bash): after Claude touches the filesystem,
  # `git add -N` every untracked `.nix` in the enclosing flake repo, so flakes
  # (which ignore untracked files) can see brand-new modules. Write/Edit carry a
  # `.tool_input.file_path`; Bash carries only `.cwd`, so we can't key on a single
  # path — instead we stage all untracked `.nix` in the repo. `add -N` on an
  # already-tracked file is a no-op, and the `flake.nix` guard keeps us from
  # mutating git index state in unrelated repos.
  nix-intent-add = pkgs.writeShellApplication {
    name = "nix-intent-add";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      input=$(cat)
      fp=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
      cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
      if [ -n "$fp" ]; then dir=$(dirname "$fp"); else dir="$cwd"; fi
      [ -n "$dir" ] || exit 0
      cd "$dir" 2>/dev/null || exit 0
      git rev-parse --git-dir >/dev/null 2>&1 || exit 0
      root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
      [ -e "$root/flake.nix" ] || exit 0
      cd "$root" || exit 0
      while IFS= read -r -d "" f; do
        git add -N -- "$f" 2>/dev/null || true
      done < <(git ls-files -o --exclude-standard -z -- '*.nix')
    '';
  };

  # Stop hook: fires when Claude finishes a turn. Auto-formats and validates any
  # flake in the cwd (surfacing failures back to Claude so it fixes them before
  # finishing), then publishes the turn's working tree as the `for-user`
  # snapshot ref (fetched from aspersum by `git receive`/`claude-do`) and
  # refreshes the legacy ~/claude.patch. `nix` is inherited from the
  # direnv-activated devshell env (which sets NIX_CONFIG for the agenix plugin).
  claude-stop-hook = pkgs.writeShellApplication {
    name = "claude-stop-hook";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
      pkgs.coreutils
      pkgs.nix
      pkgs.mollusca.git-snapshot
      mkpatch
    ];
    text = ''
      input=$(cat)
      stop_active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)

      # Feed a failure back to Claude (exit 2) so it keeps working — but only
      # once per stop cluster, so an unfixable error can't loop forever.
      surface() {
        if [ "$stop_active" = "true" ]; then
          exit 0
        fi
        printf '%s\n' "$1" >&2
        exit 2
      }

      if [ -e flake.nix ]; then
        if ! out=$(nix fmt 2>&1); then
          surface "nix fmt failed:
      $out"
        fi
        if ! out=$(nix flake check 2>&1); then
          surface "nix flake check failed; fix before finishing:
      $out"
        fi
      fi

      if git rev-parse --git-dir >/dev/null 2>&1; then
        git-snapshot --ref for-user >/dev/null 2>&1 || true
        mkpatch >/dev/null 2>&1 || true
      fi
      exit 0
    '';
  };
in
{
  imports = [
    "${self}/profiles/headless.nix"
    ./hardware-configuration.nix
    ./disko.nix
    self.inputs.impermanence.nixosModules.impermanence
  ];

  system.tools = {
    nixos-rebuild.enable = false;
    nixos-install.enable = false;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
  boot.kernel.sysctl = {
    # zram is RAM-backed, swap eagerly
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
  };

  systemd.oomd.enable = false;
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    extraArgs = [
      "--avoid"
      "^(sshd|systemd|tailscaled)$"
      "--prefer"
      "^(cc1|cc1plus|rustc|ld|cargo|ninja|gcc|go)$"
    ];
  };

  nix.settings = {
    max-jobs = 2;
    cores = 2;
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
        ".claude/projects"
      ];
      files = [
        ".claude/.credentials.json"
      ];
    };
  };

  environment = {
    systemPackages = [
      claude-code-wrapped
      pkgs.mcp-nixos
      pkgs.uv
      pkgs.tmux
      pkgs.git
      pkgs.curl
      pkgs.jq
      pkgs.ripgrep
      pkgs.fd
      pkgs.tree
      pkgs.htop
      pkgs.python3
      pkgs.file
      pkgs.less
      pkgs.abduco
      pkgs.wget
      pkgs.unzip
      pkgs.gnumake
      pkgs.gcc
      pkgs.openssh
      pkgs.diffutils
      pkgs.patch
      pkgs.which
      mkpatch
      pkgs.mollusca.git-snapshot
    ];

    etc."claude-code/managed-settings.json".text = builtins.toJSON {
      hooks = {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${claude-stop-hook}/bin/claude-stop-hook";
                timeout = 600;
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Write|Edit|Bash";
            hooks = [
              {
                type = "command";
                command = "${nix-intent-add}/bin/nix-intent-add";
              }
            ];
          }
        ];
      };
    };
  };

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
        settings = {
          user = {
            name = "Claude (glabrata)";
            email = "noreply@anthropic.com";
          };
          alias = {
            syncup = "!git fetch && { git log --oneline HEAD..@{u} || true; } && { git diff -R @{u} || true; } && git reset --hard @{u}";
            # Mirror of syncup against the `from-user` snapshot ref that
            # the user pushes directly over SSH (no GitHub round-trip).
            catchup = "!{ git log --oneline HEAD..from-user || true; } && { git diff -R from-user || true; } && git reset --hard from-user";
          };
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
        who manages this machine remotely. ${minor-secrets.shortName} is not a separate
        reviewer downstream of your work — the person who applies your patches and pushes
        them is the same person prompting you right now. Address them directly in the second
        person ("you"), or by name as ${minor-secrets.shortName}; never refer to
        ${minor-secrets.shortName} in the third person (e.g. "I'll let them know" or "they
        will push it"), which wrongly implies someone other than the person you are talking to.

        ${minor-secrets.extraText}

        ## System overview

        - **OS**: NixOS 26.05 (declarative, immutable system config)
        - **User**: `claude` (wheel group, passwordless sudo)
        - **Network**: Tailscale VPN; internet access available
        - **Resources**: ~8 GiB RAM, ~76 GiB disk (mostly free)

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
        produce a patch and deliver it via the collaboration workflow for deployment.

        ## Machine configuration

        This machine's NixOS config lives at `https://github.com/Akiiino/mollusca` in the
        `machines/glabrata/` directory. Key files:
        - `default.nix` — main config (users, services, packages, home-manager)
        - `disko.nix` — disk partitioning layout
        - `hardware-configuration.nix` — QEMU guest hardware

        Shared modules live under `modules/` (`core/` is imported by every
        machine; `desktop/`, `hardware/`, `services/`, `home/` are opt-in) —
        see the repo README for the full layout.

        ## Persistence across reinstalls

        The machine may be wiped and rebuilt at any time. What survives:
        - **Persistent volume**: `/mnt/persist` mirrors the real filesystem layout.
          Paths on the volume are bind-mounted to their real locations at boot.
          Currently persisted: Claude project folder (`~/.claude/projects`) and
          OAuth credentials (`~/.claude/.credentials.json`).
        - **System config**: Everything in the mollusca repo
        - **Nothing else**: Treat local state as ephemeral

        ## Working with projects

        - **Repo location**: Always clone and work on repos in `~/git/`.
          Changes are pulled from glabrata over Tailscale SSH, so repos must
          be at a stable, predictable path (e.g., `~/git/<repo-name>`).
        - direnv + nix-direnv are installed — entering a directory with a `flake.nix`
          and `.envrc` will automatically activate the devshell
        - Git is configured as "Claude (glabrata)" <noreply@anthropic.com>
        - You can clone repos, create branches, and produce patches
        - You do not currently have push access to any remote repos
        - Remember to pull upstream changes before starting or continuing your work
        - If you need to look at another repo's contents, clone it into /tmp/ instead
          of fetching webpages

        ## Collaboration workflow

        Working trees travel between ${minor-secrets.shortName}'s machine and glabrata as
        disposable *snapshot commits* pushed/fetched directly over SSH. Snapshot commits
        are transport vehicles only: **${minor-secrets.shortName} authors, signs, and
        pushes all real commits.**
        Never create real commits on ${minor-secrets.shortName}'s behalf; your work is
        delivered as working-tree state, and ${minor-secrets.shortName} applies it with
        `git accept` (a worktree-only `git apply` of your delta) and stages and commits
        it under their own identity.

        **Receiving work (start of a task, or when asked to sync):**
        1. ${minor-secrets.shortName} pushes their working tree — dirty state, untracked
           files and all — to the local ref `from-user` (via `git send` or `claude-do`
           on their side).
        2. Run `git catchup` — shows what changed vs your current state, then
           `git reset --hard from-user`. Read the entire output rather than
           `| head -n *`-ing it, so you build on top of what was accepted or changed.
           Note: `reset --hard` doesn't delete untracked files, so stray files you
           created earlier may survive a catchup — remove them if they're not part
           of the task.

        **Delivering changes:**
        1. Do your work. No commit is required — and per the rule above, don't make one.
        2. When you finish a turn, the Stop hook automatically publishes your working
           tree (tracked changes AND untracked files, honoring .gitignore) as a snapshot
           commit on the local ref `for-user`, parented on HEAD — so `for-user^..for-user`
           is always exactly your delta. It mutates nothing else (throwaway index; your
           branch, index, and working tree are untouched). The legacy `~/claude.patch`
           is refreshed too, as a fallback.
        3. Say in your reply that the changes are ready. On the other side they arrive
           via `git receive` (fetch + summary) and are applied with `git accept`.

        In directories that are not repos, just say in your reply that the changes are
        ready to be fetched from `glabrata` manually.

        **Review comments:** ${minor-secrets.shortName} may drop an annotated diff at
        `~/review.diff`: a unified diff of your delta with review comments inserted as
        `#|` lines directly under the lines they refer to. When asked to address review
        comments, read that file — each `#|` block is a comment anchored to the diff
        line(s) above it. Address every comment, or explain why not.

        **After ${minor-secrets.shortName} pushes to origin:** run `git syncup` — fetches
        origin, shows what changed upstream vs your last state, then resets to upstream.
        Same full-output rule as `git catchup`.

        Commands (defined in the mollusca config, available globally):
        - `git catchup` — `{ git log --oneline HEAD..from-user || true; } && { git diff -R from-user || true; } && git reset --hard from-user` (the `git diff -R from-user` compares the incoming snapshot against your working tree, so it's empty when your on-disk files already match)
        - `git syncup` — same shape, but against `@{u}` after a `git fetch` from origin
        - `git-snapshot [--ref NAME] [-m MSG]` — what the Stop hook runs; builds a snapshot commit of the working tree in a throwaway index and prints its sha
        - `mkpatch` — legacy fallback: diff working tree vs freshly-fetched upstream → `~/claude.patch`
      '';
    };

    home.stateVersion = "23.11";
  };

  age.secrets.ds = {
    file = "${self}/secrets/ds.age";
    owner = "claude";
    group = "users";
    mode = "0400";
  };

  networking.hostName = "glabrata";
}
