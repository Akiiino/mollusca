{
  self,
  pkgs,
  ...
}:
{
  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "scanner"
      "lp"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
    ];
  };
  home-manager.users.akiiino =
    { config, ... }: # TODO: this feels ugly
    {
      imports = [
        "${self}/modules/home/direnv.nix"
        "${self}/modules/home/git.nix"
        "${self}/modules/home/kakoune"
        "${self}/modules/home/starship.nix"
        "${self}/modules/home/zsh.nix"
      ];

      home = {
        packages = with pkgs; [
          gdu
          htop
          fdupes
          wl-clipboard
        ];
        language.base = "en_US.UTF-8";

        sessionVariables = {
          XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
          GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
          ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
        };

        stateVersion = "22.05";
      };

      xdg = {
        enable = true;

        userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true; # TODO: this is a legacy value. What breaks if I change to `false` - the new default?
        };
      };

      programs = {
        bash.enable = true;
        zsh.enable = true;
        fzf.enable = true;
      };
    };
}
