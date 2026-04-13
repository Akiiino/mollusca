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

  system.tools = {
    nixos-rebuild.enable = false;
    nixos-install.enable = false;
    nixos-generate-config.enable = false;
    nixos-enter.enable = false;
    nixos-build-vms.enable = false;
    nixos-option.enable = false;
  };

  xdg.mime.enable = false;

  nixpkgs.flake.source = lib.mkForce null;
  nix = {
    registry.nixpkgs = {
      from = {
        type = "indirect";
        id = "nixpkgs";
      };
      to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        rev = inputs.nixpkgs.rev;
      };
    };
    settings.extra-nix-path = "nixpkgs=flake:nixpkgs";
  };

  # Generate with `claude setup-token`, then encrypt a file containing:
  #   CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-...
  age.secrets.claude-oauth-token = {
    file = "${self}/secrets/claude-oauth-token.age";
    owner = "builder";
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
  ];

  # Always keep a Claude Code session available for builder to attach to.
  # The OAuth token from EnvironmentFile authenticates against the subscription.
  # Restart=always respawns Claude Code after it exits (normal or error).
  systemd.services.sandbox-tmux = {
    description = "Persistent Claude Code tmux session for builder";
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      User = "builder";
      EnvironmentFile = config.age.secrets.claude-oauth-token.path;
      ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s main ${pkgs.claude-code}/bin/claude --remote-control";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t main";
      Restart = "always";
      RestartSec = 3;
    };
  };

  home-manager.users.builder =
    { ... }:
    {
      programs.bash = {
        enable = true;
        # initExtra = ''
        #   if [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
        #     exec tmux attach -t main
        #   fi
        # '';
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

  networking.hostName = "glabrata";
}
