#!/usr/bin/env bash
# Run as root on the Nonguix installer USB, from the repo checkout.
# Asks for this machine's settings, then WIPES /dev/nvme0n1 and lays out:
#   p1  1 GiB  EFI (FAT32)
#   p2  rest   LUKS2 (PBKDF2, so GRUB can unlock it) -> btrfs: @ (/), @home (/home)
# and mounts it all on /mnt, ready for 02-fill-config.sh and 03-init.sh.
set -euo pipefail

DISK=/dev/nvme0n1
EFI=${DISK}p1
LUKS=${DISK}p2
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SETTINGS="$HERE/settings.env"

die() { echo "error: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run as root"
[ "${1:-$DISK}" = "$DISK" ] || die "refusing: this script only installs to $DISK"
[ -b "$DISK" ] || die "$DISK not found"
[ -d /sys/firmware/efi ] || die "not booted in UEFI mode"
! mountpoint -q /mnt || die "/mnt is already mounted; run 'umount -R /mnt' first"
[ ! -e /dev/mapper/cryptroot ] || die "cryptroot is already open; run 'cryptsetup close cryptroot' first"

# --- Settings ---------------------------------------------------------------

# ask VAR PROMPT DEFAULT REGEX
ask() {
    local val
    while :; do
        read -rp "$2 [$3]: " val
        val=${val:-$3}
        [[ $val =~ $4 ]] && break
        echo "  not valid: '$val'"
    done
    printf -v "$1" '%s' "$val"
}

# No quotes, backslashes, | or & : the values go into Scheme strings via sed.
SAFE='[^"\\|&]'
echo "Settings for this machine (Enter keeps the default):"
ask HOSTNAME  "  Hostname " "gUn" '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
ask FULL_NAME "  Full name" "Paul Harper" "^${SAFE}+$"
ask GIT_EMAIL "  Git email" "harper.paul.j@gmail.com" "^[^@[:space:]\"\\\\|&]+@[^@[:space:]\"\\\\|&]+\\.[^@[:space:]\"\\\\|&]+$"

{
    echo "# Written by install/01-partition.sh; read by 02-fill-config.sh and 04-post-install.sh."
    printf 'HOSTNAME=%q\nFULL_NAME=%q\nGIT_EMAIL=%q\n' "$HOSTNAME" "$FULL_NAME" "$GIT_EMAIL"
} > "$SETTINGS"
echo "Saved to $SETTINGS"

# --- Confirm ----------------------------------------------------------------

echo
echo "About to ERASE EVERYTHING on $DISK:"
lsblk -o NAME,SIZE,TYPE,MODEL,LABEL,FSTYPE "$DISK"
echo
read -rp "Type YES to wipe $DISK: " answer
[ "$answer" = YES ] || die "aborted, nothing changed"

# --- Partition --------------------------------------------------------------

set -x
wipefs -a "$DISK"
parted -s "$DISK" mklabel gpt \
    mkpart ESP fat32 1MiB 1025MiB set 1 esp on \
    mkpart cryptroot 1025MiB 100%
udevadm settle || sleep 2

mkfs.fat -F32 -n EFI "$EFI"

set +x
echo
echo "cryptsetup will now ask you to type YES (upper case) and choose the disk passphrase."
set -x
cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 "$LUKS"
cryptsetup open "$LUKS" cryptroot

mkfs.btrfs -L guix /dev/mapper/cryptroot

# --- Subvolumes and mounts --------------------------------------------------

mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o subvol=@,compress=zstd:3 /dev/mapper/cryptroot /mnt
mkdir -p /mnt/home /mnt/boot/efi
mount -o subvol=@home,compress=zstd:3 /dev/mapper/cryptroot /mnt/home
mount "$EFI" /mnt/boot/efi

herd start cow-store /mnt
set +x

echo
echo "Done. Next:"
echo "  mkdir -p /mnt/etc && cp -r $(dirname "$HERE") /mnt/etc/guix-system && cd /mnt/etc/guix-system"
echo "  ./install/02-fill-config.sh configuration.scm"
echo "  ./install/03-init.sh"
