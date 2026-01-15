{
  self,
  config,
  pkgs,
  lib,
  ...
}:
{
  options.mollusca = {
    isRemote = lib.mkEnableOption "remote operation & rebuilds";
    useTailscale = lib.mkEnableOption "using Tailscale";
    isExitNode = lib.mkEnableOption "using this Tailscale node as exit node";
    advertiseRoutes = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "Routes to advertise";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf config.mollusca.isRemote {
      services.openssh.enable = true;

      users.users.builder = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "video"
        ];
        openssh.authorizedKeys.keys = [
          (builtins.readFile "${self}/secrets/keys/akiiino.pub")
        ];
      };

      security.sudo.wheelNeedsPassword = false;
      services.displayManager.hiddenUsers = [ "builder" ];
    })

    (lib.mkIf (config.mollusca.isRemote && config.mollusca.useTailscale) {
      age.secrets.tailscaleKey = {
        file = "${self}/secrets/tailscale.age";
      };
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = "server";
        authKeyFile = config.age.secrets.tailscaleKey.path;
        extraUpFlags = [
          "--hostname=${config.networking.hostName}"
        ]
        ++ config.services.tailscale.extraSetFlags;
        extraSetFlags =
          (lib.optional config.mollusca.isExitNode "--advertise-exit-node")
          ++ (lib.optional (
            !(builtins.isNull config.mollusca.advertiseRoutes)
          ) "--advertise-routes=${config.mollusca.advertiseRoutes}");
        disableUpstreamLogging = true;
        disableTaildrop = true;
      };
      networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    })
  ];
}
