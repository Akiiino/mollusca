{
  modulesPath,
  self,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    self.inputs.disko.nixosModules.disko
  ];
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "table";
        format = "gpt";
        partitions = [
          {
            name = "boot";
            start = "0";
            end = "1M";
            flags = ["bios_grub"];
          }
          {
            name = "ESP";
            start = "1M";
            end = "512M";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          }
          {
            name = "nix";
            start = "512M";
            end = "70%";
            part-type = "primary";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
            };
          }
          {
            name = "home";
            start = "70%";
            end = "80%";
            part-type = "primary";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          }
          {
            name = "persist";
            start = "80%";
            end = "100%";
            part-type = "primary";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/persist";
            };
          }
        ];
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=2G"
        "defaults"
        "mode=755"
      ];
    };
  };
  boot.loader.grub = {
    device = "/dev/sda";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/persist" = {
    neededForBoot = true;
  };
  fileSystems."/home" = {
    neededForBoot = true;
  };
}
