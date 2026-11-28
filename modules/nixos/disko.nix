# The disk, for both machines: a 1 GiB EFI partition, the rest LUKS2 with
# btrfs inside (subvolumes as Debian's Timeshift layout had, plus /nix).
# disko mounts by partition label, so no UUIDs anywhere. systemd-boot
# keeps the kernels on the unencrypted ESP, so the passphrase is asked
# once, by the initrd.
{ config, ... }:
let
  btrfsOpts = [
    "compress=zstd:3"
    "noatime"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = config.my.disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = [
              "-n"
              "EFI"
            ];
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [
                "-f"
                "-L"
                "root"
              ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = btrfsOpts;
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = btrfsOpts;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = btrfsOpts;
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = btrfsOpts;
                };
              };
            };
          };
        };
      };
    };
  };
}
