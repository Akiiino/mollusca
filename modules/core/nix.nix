{
  config,
  self,
  inputs,
  ...
}:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      use-xdg-base-directories = true;
      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
    };
    channel.enable = false;
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = import "${self}/overlays" { inherit self inputs; };
  };

  systemd.services.gc-generations = {
    description = "Delete old NixOS generations, keeping the last 5";
    serviceConfig.Type = "oneshot";
    path = [ config.nix.package ];
    script = ''
      nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
      nix-collect-garbage
    '';
  };

  systemd.timers.gc-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
