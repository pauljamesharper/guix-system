# alteredcarbon: Lenovo ThinkPad X1 Carbon Gen 10 (21CB00BYFQ), i7-1255U,
# Iris Xe graphics, Intel Wi-Fi, Synaptics fingerprint reader (06cb:00fc).
# hardware.nix is written by scripts/install.sh (nixos-generate-config);
# until then this host doesn't build.
{ lib, ... }:
{
  imports = lib.optional (builtins.pathExists ./hardware.nix) ./hardware.nix;

  my = {
    disk = "/dev/disk/by-id/nvme-Micron_MTFDKBA2T0TFH_22323C4A349C";
    laptop = true;
    cpu = "intel";
    fingerprint = true;
  };

  hardware.trackpoint = {
    enable = true;
    emulateWheel = true; # middle button + TrackPoint scrolls
  };
}
