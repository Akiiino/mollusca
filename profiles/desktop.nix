{ self', ... }: {
  imports = [ ../modules/desktop/gui.nix ];

  mollusca = {
    isRemote = true;
    useTailscale = true;
    bluetooth.enable = true;
    logitech.wireless.enable = true;
    eightbitdo.enable = true;
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    fwupd.enable = true;
    printing = {
      enable = true;
      drivers = [ self'.packages.cups-brother-dcpl3520cdw ];
    };
  };

  security.rtkit.enable = true; # realtime scheduling for pipewire

  hardware.graphics.enable = true;
  programs.steam.enable = true;
}
