{
  self,
  config,
  pkgs,
  lib,
  ...
}: {
  options.mollusca = {
    isRemote = lib.mkEnableOption "remote operation & rebuilds";
    useTailscale = lib.mkEnableOption "using Tailscale";
    isExitNode = lib.mkEnableOption "using this Tailscale node as exit node";
  };
  config = lib.mkMerge [
    (lib.mkIf config.mollusca.isRemote {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = lib.mkForce "no";
        };
      };

      users.users.builder = {
        isNormalUser = true;
        extraGroups = ["wheel" "video"];
        openssh.authorizedKeys.keys = [
          (builtins.readFile "${self}/secrets/keys/akiiino.pub")
        ];
      };

      security.sudo.wheelNeedsPassword = false;
      services.xserver.displayManager.hiddenUsers = ["builder"];
    })
    (lib.mkIf (config.mollusca.isRemote && config.mollusca.useTailscale) {
      services.tailscale.enable = true;
      age.secrets.tailscaleKey = {
        file = "${self}/secrets/tailscale.age";
      };
      systemd.services.tailscale-autoconnect = {
        description = "Automatic connection to Tailscale";

        after = ["network-pre.target" "tailscale.service"];
        wants = ["network-pre.target" "tailscale.service"];
        wantedBy = ["multi-user.target"];

        serviceConfig.Type = "oneshot";

        script = with pkgs; ''
          # wait for tailscaled to settle
          sleep 2

          # check if we are already authenticated to tailscale
          status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
          if [ $status = "Running" ]; then # if so, then do nothing
            exit 0
          fi

          # otherwise authenticate with tailscale
          ${tailscale}/bin/tailscale up ${lib.optionalString config.mollusca.isExitNode "--advertise-exit-node"} --auth-key file:${config.age.secrets.tailscaleKey.path}
        '';
      };
      networking.firewall = {
        trustedInterfaces = ["tailscale0"];
        allowedUDPPorts = [config.services.tailscale.port];
      };
    })
  ];
}
