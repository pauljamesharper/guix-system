#!/usr/bin/env bash
# Run as root on the installer USB, after 02-fill-config.sh.
# Installs the system onto /mnt with the pinned channels. This takes a long
# time: it pulls the pinned Guix, then builds mangowm-patch, thunar-patch and
# friends locally. Warnings about channels "without introduction" (mangowm,
# noctalia) are expected.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO"

die() { echo "error: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run as root"
mountpoint -q /mnt || die "/mnt is not mounted; run 01-partition.sh first"
mountpoint -q /mnt/boot/efi || die "/mnt/boot/efi is not mounted"
! grep -qE '@(HOSTNAME|FULL_NAME|LUKS_UUID|EFI_UUID)@' configuration.scm \
    || die "configuration.scm still has placeholders; run 02-fill-config.sh"

guix time-machine -C channels.scm -- system init configuration.scm /mnt \
    --substitute-urls="https://bordeaux.guix.gnu.org https://ci.guix.gnu.org https://substitutes.nonguix.org"

cat <<'EOF'

Installed. Now:
  1. reboot
  2. remove the USB stick
  3. type the LUKS passphrase at GRUB (PBKDF2 unlock is slow: give it 10-20 s)
  4. log in as pharper with the password: changeme
  5. cd /etc/guix-system && ./install/04-post-install.sh
EOF
