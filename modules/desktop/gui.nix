{
  config,
  pkgs,
  lib,
  ...
}:
{
  services = {
    displayManager.hiddenUsers = builtins.attrNames (
      lib.filterAttrs (
        _: userConfig:
        (userConfig.password == null)
        && (userConfig.hashedPassword == null)
        && (userConfig.passwordFile == null)
      ) config.users.users
    );
  };
  networking.networkmanager.enable = true;
  fonts.packages = [
    pkgs.inter
    pkgs.fira-code
    pkgs.nerd-fonts.hack
    pkgs.iosevka
    pkgs.noto-fonts
    pkgs.noto-fonts-color-emoji
    pkgs.noto-fonts-cjk-sans
  ];
  boot = {
    plymouth.enable = true;
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    loader.timeout = 1;
  };
}
