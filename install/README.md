# Installing this config

Guix System with MangoWM + Noctalia, the Nonguix kernel (for WiFi), LUKS2 with
btrfs subvolumes `@` (/) and `@home` (/home), and snapper on `/home`.

| Script | Where | What |
|---|---|---|
| `01-partition.sh` | installer USB, root | asks hostname / full name / git email, then **wipes `/dev/nvme0n1`**, creates EFI + LUKS2 + btrfs, mounts on `/mnt` |
| `02-fill-config.sh` | installer USB, root | fills hostname, full name and the two UUIDs into `configuration.scm` |
| `03-init.sh` | installer USB, root | `guix system init` with the pinned channels |
| `04-post-install.sh` | installed system, as `pharper` | passwords, DNS fix, git identity, `guix pull`, snapper, v4l2loopback check |

Your answers to `01`'s questions are saved in `install/settings.env`
(gitignored) and reused by `02` and `04`.

## Phase 2: install (from the USB)

0. **Back up first.** Everything that matters in `/var/home/pharper` must be on
   another disk or in the cloud. `/dev/nvme0n1` will be wiped.
1. Secure Boot is already off on gUn. Boot the Nonguix installer USB and pick
   the shell install from the installer menu.
2. Get on WiFi:
   ```bash
   rfkill unblock all
   connmanctl        # enable wifi, scan wifi, services, agent on, connect wifi_…
   ping -c3 gnu.org
   ```
3. Get the repo and run the scripts:
   ```bash
   guix shell git -- git clone -b paul-install https://github.com/pauljamesharper/guix-system /tmp/gs
   cd /tmp/gs
   ./install/01-partition.sh
   mkdir -p /mnt/etc && cp -r /tmp/gs /mnt/etc/guix-system && cd /mnt/etc/guix-system
   ./install/02-fill-config.sh configuration.scm
   ./install/03-init.sh
   ```
   `01` asks three questions first (Enter keeps the default: `gUn`,
   `Paul Harper`, `harper.paul.j@gmail.com`), then shows the disk and wants
   `YES` before wiping. `cryptsetup` then asks for `YES` again and the new
   passphrase.

   `03-init.sh` takes a long time: it pulls the pinned Guix, then builds
   `mangowm-patch`, `thunar-patch` and similar packages locally. Warnings about
   channels "without introduction" (mangowm, noctalia) are expected.

   gUn has 7.4 GiB RAM and the live system has no swap. If the build is killed
   for lack of memory, add a swap file on the target and re-run `03`:
   ```bash
   truncate -s 0 /mnt/swapfile && chattr +C /mnt/swapfile   # no copy-on-write
   fallocate -l 8G /mnt/swapfile && chmod 600 /mnt/swapfile
   mkswap /mnt/swapfile && swapon /mnt/swapfile
   ./install/03-init.sh
   swapoff /mnt/swapfile && rm /mnt/swapfile   # after it finishes
   ```
4. Reboot and remove the USB stick. GRUB asks for the LUKS passphrase; the
   PBKDF2 unlock is slow, so give it 10–20 seconds.

## Phase 3: first boot

GRUB passes the key it unlocked to the initrd, so the passphrase is asked for
**once**. If you are asked a second time, the built-in hand-over didn't work:
the system still boots, and a key-file fallback can be added later.

Log in as `pharper` with the password `changeme`, then:

```bash
cd /etc/guix-system
./install/04-post-install.sh
```

From then on, after `git pull` in `/etc/guix-system`, apply changes with:

```bash
sudo guix system reconfigure /etc/guix-system/configuration.scm
```

To roll back the system, pick an older generation in GRUB's "GNU system, old
configurations" menu or run `sudo guix system roll-back`. To restore files in
`/home`, copy them from `/home/.snapshots/<n>/snapshot/` or use
`snapper --no-dbus -c home undochange`.
