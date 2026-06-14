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
        --add-flags "--mcp-config ${mcpJson}"
    '';
    inherit (pkgs.claude-code) meta;
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    self.inputs.impermanence.nixosModules.impermanence
    # "${modulesPath}/profiles/perlless.nix"
    # ./rinkaru.nix
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

  environment.systemPackages = with pkgs; [
    claude-code-wrapped
    mcp-nixos
    fli-mcp
    uv
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
            mkpatch = "!git diff --quiet && git diff --cached --quiet || { echo 'Error: uncommitted changes exist. Commit or stash them first.'; exit 1; } && git diff @{u} HEAD > ~/claude.patch && echo 'Patch written to ~/claude.patch'";
            syncup = "!git fetch && git diff HEAD..@{u} && git reset --hard @{u}";
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
        who manages this machine remotely. Address the operator directly in second person:
        as "you", or by name as ${minor-secrets.shortName} — but always in second person,
        never third person.

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
          Currently persisted: Claude project folder (`~/.claude/projects`) and
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
        - If you need to look at another repo's contents, clone it into /tmp/ instead of fetching webpages

        ## Collaboration workflow

        Use this workflow when making code changes for ${minor-secrets.shortName} to review:

        **Delivering changes:**
        1. Do your work, making one or multiple commits locally as needed (WIP commits are fine).
        2. When ready, run `git mkpatch` — writes all changes vs upstream to `~/claude.patch`.
        3. Tell ${minor-secrets.shortName} the patch is ready. They apply it with:
           `ssh claude@glabrata 'cat ~/claude.patch' | git apply -`
        4. ${minor-secrets.shortName} modifies as needed, commits, and pushes to `origin`.

        **Continuing after ${minor-secrets.shortName} pushes:**
        1. Run `git syncup` — fetches origin, shows what ${minor-secrets.shortName} changed vs your last commit,
           then resets to upstream. Note that if you're continuing your work it's more token-efficient to read
           the entire output of `git syncup`, rather than `| head -n *` it and have to look through `git log`
           and read the files again.
        2. Continue working from the clean upstream state.

        Git aliases (defined in home-manager, available globally):
        - `git mkpatch` — `git diff @{u} HEAD > ~/claude.patch`
        - `git syncup` — `git fetch && git diff HEAD..@{u} && git reset --hard @{u}`
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
