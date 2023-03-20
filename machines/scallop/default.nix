{
  self,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./services/acme.nix
    ./services/nitter.nix
    ./services/grocy.nix
    ./services/nextcloud.nix
    ./services/secondbrain.nix
    ./services/oauth-proxy.nix
    ./services/404.nix
  ];
  nix.settings.auto-optimise-store = true;

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = "scallop";
  networking.domain = "";
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [kakoune hydroxide];

  networking.firewall.allowedTCPPorts = [80 443];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  system.stateVersion = "22.05";
}
