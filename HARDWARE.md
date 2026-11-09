# Hardware: gUn

Surveyed 2026-11-09 from Aurora on this machine (Lenovo 12SA0002FQ).

| Part | Found | Config decision |
|---|---|---|
| CPU | 13th Gen Intel Core i7-13620H (10 cores, 16 threads, VT-x) | — |
| RAM | 7.4 GiB | keep zram (6G); `guix system init` builds a few packages locally, so this is tight on the live USB |
| GPU | Intel Raptor Lake-P UHD Graphics `[8086:a7a8]`, driver `i915` (no NVIDIA, no AMD) | no NVIDIA transform; plain `obs`, `steam`, `heroic`; keep `intel-media-driver` |
| WiFi | Intel Raptor Lake PCH CNVi WiFi `[8086:51f1]`, driver `iwlwifi` | Nonguix `linux` kernel and `linux-firmware`; no Broadcom recipe needed |
| Bluetooth | Intel AX201 `[8087:0026]` (USB) | covered by `linux-firmware` |
| Firmware | UEFI | `grub-efi-bootloader` on `/boot/efi` |
| Secure Boot | disabled | nothing to change in firmware settings |
| Target disk | `/dev/nvme0n1`, WD PC SN740 512 GB | wiped by `install/01-partition.sh` |

Commands used:

```bash
lspci -nnk | grep -EA3 'VGA|3D|Display|Network|Wireless'
lscpu | head -20
free -h
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
mokutil --sb-state
```
