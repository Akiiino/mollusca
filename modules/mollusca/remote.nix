{
  self,
  config,
  lib,
  ...
}:
{
  options.mollusca = {
    isRemote = lib.mkEnableOption "remote operation & rebuilds";
    useTailscale = lib.mkEnableOption "using Tailscale";
    isExitNode = lib.mkEnableOption "using this Tailscale node as exit node";
    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.1.0/24" ];
      description = "Subnet routes to advertise to other Tailscale peers.";
    };
    tailscaleRoutingFeatures = lib.mkOption {
      type = lib.types.enum [
        "none"
        "client"
        "server"
        "both"
      ];
      default = "server";
      description = ''
        Tailscale routing features mode (passed to services.tailscale).
        Use "client" on machines that consume exit nodes / subnet routes
        but don't advertise any; "server" on machines that advertise.
      '';
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

    (lib.mkIf config.mollusca.useTailscale {
      age.secrets.tailscaleKey.file = "${self}/secrets/tailscale.age";
      services.tailscale = {
        enable = true;
        openFirewall = true;
        useRoutingFeatures = config.mollusca.tailscaleRoutingFeatures;
        authKeyFile = config.age.secrets.tailscaleKey.path;
        extraUpFlags = [
          "--hostname=${config.networking.hostName}"
        ]
        ++ config.services.tailscale.extraSetFlags;
        extraSetFlags =
          (lib.optional config.mollusca.isExitNode "--advertise-exit-node")
          ++ (lib.optional (
            config.mollusca.advertiseRoutes != [ ]
          ) "--advertise-routes=${lib.concatStringsSep "," config.mollusca.advertiseRoutes}");
        disableUpstreamLogging = true;
        disableTaildrop = true;
      };
      networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
    })
  ];
}
