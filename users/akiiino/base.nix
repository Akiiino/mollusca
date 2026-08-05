{
  self,
  config,
  pkgs,
  secretFile,
  ...
}:
{
  age.secrets.akiiino-password.file = secretFile "akiiino-password.age";

  users.users.akiiino = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.age.secrets.akiiino-password.path;
    openssh.authorizedKeys.keys = [
      (builtins.readFile "${self}/secrets/keys/akiiino.pub")
    ];
  };
  home-manager.users.akiiino =
    # The lambda rebinds `config` to home-manager's own config (for xdg.* paths)
    # instead of the NixOS one. Same pattern in desktop.nix and personal.nix.
    { config, ... }:
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
