{
  modulesPath,
  self,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    self.inputs.disko.nixosModules.disko
  ];
  disko.devices = {
    disk.main = {
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          nix = {
            name = "nix";
            size = "200G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
            };
          };
          steam = {
            name = "steam";
            size = "1500G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home/nautilus/SteamLibrary";
            };
          };
          swap = {
            size = "50G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          nixos = {
            name = "nixos";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/home/akiiino/SteamLibrary" = {
    device = "/dev/disk/by-partlabel/disk-main-steam";
  };
  # fileSystems."/steam".options = ["uid=1002" "gid=100"];
}
