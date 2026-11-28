#!/usr/bin/env bash
# install.sh — install NixOS on gUn or alteredcarbon from the live ISO.
# shellcheck disable=SC2015  # "a && b || die" is meant: die when any test fails
#
# On the live system (graphical ISO), connect to the network, then:
#   git clone https://github.com/pauljamesharper/nixos
#   cd nixos && git checkout nixos      # until it is merged into main
#   sudo ./scripts/install.sh
#
# It asks the hostname and, for a machine it doesn't know yet, the disk,
# and writes hosts/<hostname>/ from the hardware. It WIPES that disk:
# disko partitions it (1 GiB EFI, the rest LUKS2 + btrfs) and asks the new
# disk passphrase. Then nixos-install, your password, this repo in
# /etc/nixos and the dotfiles in ~/dotfiles. Nothing long to type.
set -euo pipefail

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
ask()  { local a; read -r -p "$1 " a </dev/tty; printf %s "$a"; }

USER_NAME=pharper
DOTFILES_URL=https://codeberg.org/gluesniffmonkey/dotfiles.git
NIX=(nix --extra-experimental-features "nix-command flakes")

[ "$(id -u)" = 0 ] || die "run it with sudo"
REPO=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
[ -f "$REPO/flake.nix" ] || die "can't find the repo (no flake.nix in $REPO)"
cd "$REPO"

# --------------------------------------------------------------------------
say "Network"
if ! curl -fsS --max-time 10 -o /dev/null https://cache.nixos.org; then
    echo "No connection to cache.nixos.org. Connect with the network icon," >&2
    echo "or for Wi-Fi in a terminal:  nmcli device wifi connect <SSID> --ask" >&2
    exit 1
fi
echo ok

# --------------------------------------------------------------------------
say "Hostname"
known=$(find hosts -mindepth 1 -maxdepth 1 -type d -printf '%f ' 2>/dev/null)
echo "known: ${known:-none}"
HOST=$(ask "Hostname for this machine:")
[[ "$HOST" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$ ]] || die "'$HOST' isn't a valid hostname"
HOSTDIR="hosts/$HOST"

# what this machine is
cpu=intel
grep -q AuthenticAMD /proc/cpuinfo && cpu=amd
laptop=false
ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && laptop=true
# a Synaptics (06cb) USB fingerprint reader, as Debian's installer looks for
fingerprint=false
grep -qx 06cb /sys/bus/usb/devices/*/idVendor 2>/dev/null && fingerprint=true
echo "this machine: $cpu CPU, laptop: $laptop, fingerprint reader: $fingerprint ($(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_version 2>/dev/null | tr '\n' ' '))"

# --------------------------------------------------------------------------
say "Disk"
pick_disk() {
    local ids=() d i=1
    for d in /dev/disk/by-id/*; do
        case "$d" in *-part*|*/wwn-*|*/nvme-eui.*|*_1) continue ;; esac
        [ "$(lsblk -dno TYPE "$d" 2>/dev/null)" = disk ] || continue
        # not the stick this runs from
        [ "$(lsblk -dno TRAN "$d")" = usb ] && continue
        ids+=("$d")
    done
    [ ${#ids[@]} -gt 0 ] || die "no internal disk found"
    for d in "${ids[@]}"; do
        printf '  %d) %-8s %8s  %s\n' $i "$(basename "$(readlink -f "$d")")" \
            "$(lsblk -dno SIZE "$d")" "${d#/dev/disk/by-id/}" >/dev/tty
        i=$((i + 1))
    done
    local n
    n=$(ask "Install on which disk (number)?")
    [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le ${#ids[@]} ] || die "no disk $n"
    printf %s "${ids[$((n - 1))]}"
}

if [ -f "$HOSTDIR/default.nix" ]; then
    DISK=$(sed -n 's/^ *disk = "\(.*\)";/\1/p' "$HOSTDIR/default.nix")
    if [ ! -e "$DISK" ]; then
        echo "$HOSTDIR says disk $DISK, which this machine doesn't have." >&2
        [ "$(ask "Is this machine really $HOST? [y/N]")" = y ] || exit 1
        DISK=$(pick_disk)
        sed -i "s|^\( *disk = \)\".*\";|\1\"$DISK\";|" "$HOSTDIR/default.nix"
    fi
    grep -q "laptop = $laptop;" "$HOSTDIR/default.nix" \
        || echo "warning: $HOSTDIR doesn't say laptop = $laptop; check it after" >&2
    grep -q "cpu = \"$cpu\";" "$HOSTDIR/default.nix" \
        || echo "warning: $HOSTDIR doesn't say cpu = \"$cpu\"; check it after" >&2
else
    DISK=$(pick_disk)
    mkdir -p "$HOSTDIR"
    cat > "$HOSTDIR/default.nix" <<EOF
# $HOST: $(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_version 2>/dev/null | tr '\n' ' ')
# (written by scripts/install.sh). hardware.nix: nixos-generate-config.
{ lib, ... }:
{
  imports = lib.optional (builtins.pathExists ./hardware.nix) ./hardware.nix;

  my = {
    disk = "$DISK";
    laptop = $laptop;
    cpu = "$cpu";
    fingerprint = $fingerprint;
  };
}
EOF
    echo "wrote $HOSTDIR/default.nix"
fi

[ -n "${DISK:-}" ] && [ -e "$DISK" ] || die "no disk chosen"
dev=$(basename "$(readlink -f "$DISK")")
echo
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$DISK"
echo
echo "EVERYTHING on $dev ($(lsblk -dno SIZE,MODEL "$DISK" | xargs)) will be erased."
[ "$(ask "Type $dev to go on:")" = "$dev" ] || die "stopped; nothing was changed"

# --------------------------------------------------------------------------
say "Hardware configuration"
nixos-generate-config --no-filesystems --show-hardware-config > "$HOSTDIR/hardware.nix"
# a flake only sees files git knows about
git add "$HOSTDIR"
echo "wrote $HOSTDIR/hardware.nix"

# --------------------------------------------------------------------------
say "Partitioning, encryption, btrfs (disko); choose the disk passphrase"
"${NIX[@]}" run github:nix-community/disko/latest -- \
    --mode destroy,format,mount --yes-wipe-all-disks --flake ".#$HOST"
findmnt /mnt >/dev/null || die "disko didn't mount /mnt"

# --------------------------------------------------------------------------
say "Installing (downloads a few GB; re-run this script if it fails)"
for try in 1 2 3; do
    nixos-install --flake ".#$HOST" --no-root-passwd --no-channel-copy && break
    [ $try = 3 ] && die "nixos-install failed three times"
    echo "retrying ($try of 3 failed)"
    sleep 5
done

# --------------------------------------------------------------------------
say "Your password ($USER_NAME: login, sudo, keyring)"
until nixos-enter --root /mnt -c "passwd $USER_NAME" </dev/tty; do :; done

# --------------------------------------------------------------------------
say "This repo in /etc/nixos, the dotfiles in ~/dotfiles"
rm -rf /mnt/etc/nixos
cp -a "$REPO" /mnt/etc/nixos
chown -R 1000:100 /mnt/etc/nixos
home=/mnt/home/$USER_NAME
if [ ! -d "$home/dotfiles" ]; then
    git clone -q "$DOTFILES_URL" "$home/dotfiles"
    git -C "$home/dotfiles" checkout -q nixos 2>/dev/null \
        || echo "note: the dotfiles have no 'nixos' branch yet; using their default branch" >&2
fi
mkdir -p "$home/src"
ln -sfn /etc/nixos "$home/src/nixos"
chown -R 1000:100 "$home"

cat <<EOF

Done. Take out the USB stick and reboot.

First boot:
  - the disk passphrase, then log in as $USER_NAME in tuigreet (mango)
  - Home Manager has stowed ~/dotfiles and set up the bar; if it warned,
    see: journalctl -b -u home-manager-$USER_NAME
  - mise install                 (Claude Code, gh, cliamp, etesync-dav, ...)
  - Superwhisper:
      curl -fsSL --proto '=https' https://tux.superwhisper.com/install.sh | SW_SKIP_PACKAGES=1 sh
  - commit hosts/$HOST in /etc/nixos (~/src/nixos) and push it
EOF
