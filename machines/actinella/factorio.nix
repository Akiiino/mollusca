{ pkgs, ... }:
{
  services.factorio = {
    enable = true;
    package = pkgs.factorio-headless.override { versionsJson = ./factorio-versions.json; };

    lan = true;
    public = false;
    openFirewall = true;
    bind = "192.168.1.101";

    saveName = "default";
    loadLatestSave = true;
    autosave-interval = 5;
    nonBlockingSaving = true;

    admins = [
      "akiiino"
      "rinkaru"
    ];

    game-name = "Speeedy";
  };
}
