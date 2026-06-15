{
  self,
  pkgs,
  minor-secrets,
  ...
}:
let
  fli-mcp = pkgs.writeShellScriptBin "fli-mcp" ''
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${pkgs.uv}/bin/uv tool run --with click --from flights[mcp] fli-mcp "$@"
  ''; # TODO: remove or properly Nixify

  # Wrap claude-code so it always loads our home-manager-managed MCP config
  # without touching the mutable ~/.claude.json or ~/.claude/settings.json.
  mcpJson = pkgs.writeText "claude-mcp.json" (
    builtins.toJSON {
      mcpServers = {
        nixos = {
          type = "stdio";
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        };
        fli = {
          type = "stdio";
          command = "${fli-mcp}/bin/fli-mcp";
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
  # finishing), then refreshes ~/claude.patch. `nix` is inherited from the
  # direnv-activated devshell env (which sets NIX_CONFIG for the agenix plugin).
  claude-stop-hook = pkgs.writeShellApplication {
    name = "claude-stop-hook";
    runtimeInputs = [
      pkgs.git
      pkgs.jq
      pkgs.coreutils
      pkgs.nix
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
        mkpatch >/dev/null 2>&1 || true
      fi
      exit 0
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    self.inputs.impermanence.nixosModules.impermanence
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
  };

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
    systemPackages =
      (with pkgs; [
        claude-code-wrapped
        mcp-nixos
        fli-mcp
        uv
        tmux
        git
        curl
        jq
        ripgrep
        fd
        tree
        htop
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
      ])
      ++ [ mkpatch ];

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
            syncup = "!git fetch && git log --oneline HEAD..@{u} && git diff -R @{u} && git reset --hard @{u}";
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

        - **OS**: NixOS 25.11 (declarative, immutable system config)
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

        Shared modules are in `modules/mollusca/` (remote.nix, gui.nix, etc.)
        and `modules/base/` (all.nix, nixos.nix).

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
        - If you need to look at another repo's contents, clone it into /tmp/ instead of fetching webpages

        ## Collaboration workflow

        Use this workflow when making code changes to hand back for review:

        **Delivering changes:**
        1. Do your work. No commit is required.
        2. When you finish your work, `mkpatch` runs automatically — it fetches upstream
           and writes your full working-tree diff (tracked changes AND new untracked files,
           with binary content) versus fresh upstream to `~/claude.patch`. It mutates nothing:
           `git fetch` only moves remote-tracking refs, and the diff is computed in a throwaway
           index, so your branch, index, and working tree are untouched.
        3. Say in your reply that the patch is ready. It gets applied with:
           `ssh claude@glabrata 'cat ~/claude.patch' | git apply -`
        4. From there it is modified as needed, committed, and pushed to `origin`.

        `mkpatch` is generic (works in any clone with an upstream). In directories that are not
        repos, or do not have an upstream, just say in your reply that the
        changes are ready to be fetched from `glabrata` manually.

        **Continuing after the changes are pushed:**
        1. Run `git syncup` — fetches origin, shows what changed upstream vs your last
           state, then resets to upstream. Read the entire output rather than
           `| head -n *`-ing it, so you see the upstream changes in full and your next
           `mkpatch` builds on top of what was accepted.
        2. Continue working from the clean upstream state.

        Commands (defined in the mollusca config, available globally):
        - `mkpatch` — diff working tree vs freshly-fetched upstream → `~/claude.patch`
        - `git syncup` — `git fetch && git log --oneline HEAD..@{u} && git diff -R @{u} && git reset --hard @{u}` (the `git diff -R @{u}` compares upstream against your working tree, so it's empty when your on-disk files already match what was pushed; `git log` still lists the new commits)
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
