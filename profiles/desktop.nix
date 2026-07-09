{
  imports = [ ../modules/desktop/gui.nix ];

  mollusca = {
    isRemote = true;
    bluetooth.enable = true;
    logitech.wireless.enable = true;
    eightbitdo.enable = true;
  };
}
