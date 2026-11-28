# Debian's 'virt' section: KVM + libvirt + virt-manager (UEFI firmware and
# a virtual TPM for Windows 11), the default NAT network on at boot, and
# rootless podman with distrobox.
{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true; # OVMF comes with QEMU
  };
  programs.virt-manager.enable = true;

  # the NAT network the VMs use by default, started now and on every boot
  systemd.services.libvirt-default-network = {
    description = "Start libvirt's default network and mark it autostart";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.libvirt ];
    script = ''
      virsh net-autostart default >/dev/null
      virsh net-info default | grep -q '^Active:.*yes' || virsh net-start default
    '';
  };

  # disk images on btrfs without copy-on-write (+C applies to files
  # created after it is set)
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0711 root root -"
    "h /var/lib/libvirt/images - - - - +C"
  ];

  virtualisation.podman.enable = true;
  environment.systemPackages = with pkgs; [
    distrobox
    podman-compose
  ];
}
