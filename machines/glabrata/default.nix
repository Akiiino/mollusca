{
  self,
  config,
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
    # "${modulesPath}/profiles/perlless.nix"
  ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
  };

  # system.tools = {
  #   nixos-rebuild.enable = false;
  #   nixos-install.enable = false;
  #   nixos-generate-config.enable = false;
  #   nixos-enter.enable = false;
  #   nixos-build-vms.enable = false;
  #   nixos-option.enable = false;
  # };

  # xdg.mime.enable = false;

  # nixpkgs.flake.source = lib.mkForce null;
  # nix = {
  #   registry.nixpkgs = {
  #     from = {
  #       type = "indirect";
  #       id = "nixpkgs";
  #     };
  #     to = {
  #       type = "github";
  #       owner = "NixOS";
  #       repo = "nixpkgs";
  #       rev = inputs.nixpkgs.rev;
  #     };
  #   };
  #   settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
  # };

  # Full credentials file from `claude auth login` — required for remote control.
  # Encrypt with: agenix -e secrets/claude-credentials.age
  # (use the contents of ~/.claude/.credentials.json)
  age.secrets.claude-credentials = {
    file = "${self}/secrets/claude-credentials.age";
    owner = "claude";
    mode = "0600";
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
  # Waits for agenix to decrypt credentials before starting.
  # ExecStartPre symlinks the decrypted credentials into ~/.claude/ so
  # Claude Code finds them at its expected path.
  systemd.services.sandbox-tmux = {
    description = "Persistent Claude Code tmux session";
    after = [
      "network-online.target"
      "tailscaled.service"
      "agenix.service"
    ];
    wants = [
      "network-online.target"
      "agenix.service"
    ];
    requires = [ "run-agenix.d.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      User = "claude";
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'mkdir -p /home/claude/.claude && ln -sf ${config.age.secrets.claude-credentials.path} /home/claude/.claude/.credentials.json'";
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main ${pkgs.claude-code}/bin/claude --remote-control --dangerously-skip-permissions --model opus";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t main";
      Restart = "always";
      RestartSec = 5;
    };
    path = [
      "/run/current-system/sw"
      "/run/wrappers"
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

      home.file.".claude/CLAUDE.md".text = ''
        # Environment

        You are running on a NixOS sandbox machine (`glabrata`).

        ## Installing tools

        This is NixOS — do not use `apt`, `brew`, etc.
        Use `nix run nixpkgs#<package>` for one-off commands,
        or `nix shell nixpkgs#<package>` to add a tool to your current shell.
        Multiple packages: `nix shell nixpkgs#foo nixpkgs#bar`.

        The nixpkgs registry is pinned, so these commands work without network
        fetches after the first use of a given package.

        ## Permissions

        You have passwordless sudo. This machine is an isolated sandbox —
        there is nothing here you can break that matters.
      '';

      home.stateVersion = "23.11";
    };

  # Keep the builder user exactly as the other machines define it
  # (via mollusca.isRemote in remote.nix). No glabrata-specific overrides.

  networking.hostName = "glabrata";
}
