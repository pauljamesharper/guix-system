#!/usr/bin/env bash
# Run once as pharper (not root) after the first boot, from /etc/guix-system.
# Sets passwords, fixes DNS, sets your git identity, commits this machine's
# filled-in config, pulls the pinned channels, sets up snapper on /home and
# checks the OBS virtual camera module.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SETTINGS="$REPO/install/settings.env"

die() { echo "error: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

[ "$(id -u)" -ne 0 ] || die "run as your user, not root (sudo is used where needed)"
[ -f "$SETTINGS" ] || die "$SETTINGS not found"
# shellcheck source=/dev/null
. "$SETTINGS"

step "Password for $(id -un) (replaces 'changeme')"
passwd

step "Password for root"
sudo passwd root

step "DNS fix (regenerate /etc/resolv.conf)"
sudo rm -f /etc/resolv.conf
sudo nmcli general reload dns-rc

step "Git identity: $FULL_NAME <$GIT_EMAIL>"
git config --global user.name "$FULL_NAME"
git config --global user.email "$GIT_EMAIL"

step "Own $REPO and commit this machine's filled-in config"
# The installer copied the repo as root; owning it lets you git pull without sudo.
sudo chown -R "$(id -un):users" "$REPO"
if ! git -C "$REPO" diff --quiet -- configuration.scm; then
    git -C "$REPO" commit -q -m "$HOSTNAME: fill in hostname, name and disk UUIDs" -- configuration.scm
    git -C "$REPO" log --oneline -1
else
    echo "nothing to commit"
fi

step "guix pull with the pinned channels"
mkdir -p ~/.config/guix
cp "$REPO/channels.scm" ~/.config/guix/channels.scm
guix pull

step "snapper on /home"
if [ -f /etc/snapper/configs/home ]; then
    echo "/etc/snapper/configs/home already exists"
else
    sudo snapper --no-dbus -c home create-config /home
fi
for kv in HOURLY=10 DAILY=7 WEEKLY=4 MONTHLY=6 YEARLY=0; do
    sudo sed -i -E "s/^(TIMELINE_LIMIT_${kv%%=*})=.*/\\1=\"${kv#*=}\"/" /etc/snapper/configs/home
done
grep '^TIMELINE_LIMIT_' /etc/snapper/configs/home

step "OBS virtual camera (v4l2loopback)"
if sudo modprobe v4l2loopback; then
    echo "OK: v4l2loopback loaded"
else
    echo "FAILED: v4l2loopback did not load. It is built against linux-libre, not the"
    echo "Nonguix kernel; drop v4l2loopback-linux-module from configuration.scm."
fi

cat <<EOF

Done. Reboot once and check GRUB asks for the passphrase only once.
After a git pull, apply changes with:
  sudo guix system reconfigure $REPO/configuration.scm
EOF
