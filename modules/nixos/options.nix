# What differs per machine; hosts/<hostname>/default.nix sets these
# (scripts/install.sh writes them from the hardware).
{ lib, ... }:
{
  options.my = {
    disk = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HCJQ-00BL7_S64KNX0T123456";
      description = "The disk disko partitions (wiped on install).";
    };
    laptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        A battery: TLP with 75-80 % charge thresholds instead of
        power-profiles-daemon, and thermald on Intel (Debian's 'hardware'
        section).
      '';
    };
    cpu = lib.mkOption {
      type = lib.types.enum [
        "intel"
        "amd"
      ];
      description = "CPU vendor (microcode comes from hardware.nix).";
    };
  };
}
