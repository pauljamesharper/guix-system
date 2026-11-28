# nixos

NixOS for **gUn** and **alteredcarbon**: the desktop my
[dotfiles](https://codeberg.org/gluesniffmonkey/dotfiles) set up on Debian
13 (mango + the mangobutter bar, Superwhisper, Proton VPN, Flatpak Steam),
as one flake. The dotfiles stay the source of every config file and are
still stowed, so they're edited in place as before.

## Layout

```
flake.nix                 inputs; one nixosConfiguration per hosts/<name>
hosts/<name>/default.nix  disk, laptop?, CPU vendor, fingerprint reader
hosts/<name>/hardware.nix nixos-generate-config (install.sh writes it)
modules/nixos/
  options.nix             my.disk, my.laptop, my.cpu, my.fingerprint
  disko.nix               1 GiB ESP + LUKS2 → btrfs (@, @home, @nix, @log)
  base.nix                boot (systemd-boot, Plymouth), nix, locale, user,
                          firmware, zram, ssh, avahi, nix-ld, debuginfod
  desktop.nix             mango, greetd/tuigreet, keyring + gcr ssh agent,
                          PipeWire, Bluetooth, Thunar, bar tools, fonts
  network.nix             NetworkManager + resolved, 1.1.1.2/1.0.0.2 on every
                          network, firewall, Proton VPN
  power.nix               TLP 75–80 % + thermald on laptops, else
                          power-profiles-daemon; fprintd
  virtualisation.nix      libvirt + virt-manager (swtpm), podman, distrobox
  flatpak.nix             the Flathub apps, Steam + Proton-GE + layers
  superwhisper.nix        what Superwhisper's vendor build needs
modules/home/             Home Manager: the apt list, git identity,
                          activation (scripts/home-activate)
pkgs/                     mangobutter, its GTK/icon themes, lxpolkit shim,
                          nixos-update
scripts/install.sh        install from the live ISO
scripts/home-activate     stow the dotfiles, enable the user units,
                          install the mangobutter files, apply mango-shell
```

## Install

Boot the NixOS graphical ISO, connect to the network, open a terminal:

```sh
git clone https://github.com/pauljamesharper/nixos
cd nixos && git checkout nixos      # until merged into main
sudo ./scripts/install.sh
```

It asks the hostname. For a host already in `hosts/` it uses the disk named
there; for a new one it lists the disks to pick from and writes
`hosts/<name>/default.nix` from the hardware (CPU vendor, battery). It
then wipes the disk (you type its name to confirm), asks the new disk
passphrase, installs, asks your password, and puts this repo in
`/etc/nixos` (linked from `~/src/nixos`) and the dotfiles in `~/dotfiles`.

After the first login:

```sh
mise install       # Claude Code, gh, uv, cliamp, etesync-dav, khal, ...
curl -fsSL --proto '=https' https://tux.superwhisper.com/install.sh | SW_SKIP_PACKAGES=1 sh
```

and commit the new `hosts/<name>/` files.

## Day to day

| Debian                                   | here                                  |
|------------------------------------------|---------------------------------------|
| `sudo apt update && sudo apt upgrade`    | `nixos-update` (the bar's Updates pill) |
| `apt list --upgradable`                  | `nixos-update --check`                |
| edit install-packages.sh, re-run it      | edit this repo, `sudo nixos-rebuild switch` |
| Timeshift / grub-btrfs snapshot          | pick an older generation at boot      |
| `stow <package>`                         | `sudo nixos-rebuild switch` (stows all) |

`nixos-update` updates `flake.lock`; commit it afterwards.

## Not carried over

- Timeshift, grub-btrfs: generations replace them
- SDDM and its butterbox theme: greetd + tuigreet
- the Emacs source build: nixpkgs' `emacs-pgtk` (31, native compilation,
  tree-sitter)
- the Mozilla and Proton apt repositories: nixpkgs' `firefox`, `proton-vpn`
- a disk swapfile: zram only
