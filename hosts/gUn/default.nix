# gUn: Lenovo ThinkCentre neo 50a 27 Gen 5 (all-in-one, no battery),
# i7-13620H, Intel graphics. hardware.nix is written by scripts/install.sh
# (nixos-generate-config); until then this host doesn't build.
{ lib, ... }:
{
  imports = lib.optional (builtins.pathExists ./hardware.nix) ./hardware.nix;

  my = {
    disk = "/dev/disk/by-id/nvme-WD_PC_SN740_SDDQNQD-512G-1201_2504H1400017";
    laptop = false;
    cpu = "intel";
  };
}
