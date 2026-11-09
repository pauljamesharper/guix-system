#!/usr/bin/env bash
# Run as root on the installer USB, after 01-partition.sh.
# Fills configuration.scm's placeholders: @HOSTNAME@ and @FULL_NAME@ from
# install/settings.env, @LUKS_UUID@ and @EFI_UUID@ from the new partitions.
set -euo pipefail

CONFIG=${1:?usage: $0 path/to/configuration.scm}
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SETTINGS="$HERE/settings.env"

die() { echo "error: $*" >&2; exit 1; }

[ -f "$CONFIG" ] || die "$CONFIG not found"
[ -f "$SETTINGS" ] || die "$SETTINGS not found; run 01-partition.sh first"
# shellcheck source=/dev/null
. "$SETTINGS"

LUKS_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
EFI_UUID=$(blkid -s UUID -o value /dev/nvme0n1p1)
[ -n "$LUKS_UUID" ] || die "no UUID on /dev/nvme0n1p2"
[ -n "$EFI_UUID" ] || die "no UUID on /dev/nvme0n1p1"

echo "Hostname:  $HOSTNAME"
echo "Full name: $FULL_NAME"
echo "LUKS UUID: $LUKS_UUID"
echo "EFI UUID:  $EFI_UUID"

sed -i \
    -e "s|@HOSTNAME@|$HOSTNAME|g" \
    -e "s|@FULL_NAME@|$FULL_NAME|g" \
    -e "s|@LUKS_UUID@|$LUKS_UUID|g" \
    -e "s|@EFI_UUID@|$EFI_UUID|g" \
    "$CONFIG"

if grep -nE '@(HOSTNAME|FULL_NAME|LUKS_UUID|EFI_UUID)@' "$CONFIG"; then
    die "placeholders left in $CONFIG (above)"
fi
echo "OK: no placeholders left in $CONFIG"
