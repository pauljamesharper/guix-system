;; Indicate which modules to import to access the variables
;; used in this configuration.
(add-to-load-path (dirname (current-filename)))

(use-modules (guix gexp)
             (guix packages)
             (gnu)
             (gnu packages linux)
             (gnu system privilege)
             (nongnu packages linux)
             (nongnu system linux-initrd)
              (modules desktop)
              (modules kernel)
              (modules packages)
              (modules services)
              (modules system)
              (modules users))

(operating-system
  (locale "en_AU.utf8")
  (timezone "Asia/Phnom_Penh")
  (keyboard-layout (keyboard-layout "us"))
  (host-name system-hostname)

  ;; The list of user accounts ('root' is implicit).
  (users (cons* user-pharper %base-user-accounts))
  (kernel linux-cachyos-bore-intel)
  (kernel-arguments '("zswap.enabled=0" "transparent_hugepage=madvise"))
  (kernel-loadable-modules (list v4l2loopback-linux-module-cachyos))
  (initrd microcode-initrd)
  (firmware (cons* linux-firmware %base-firmware))
  (packages (append (list mangowm-patch thunar-patch
                          btop-patch desktop-session-tools)
                    (specifications->packages packages-list)
                    %base-packages))

  (privileged-programs (cons (privileged-program
                               (program (file-append
                                         btop-patch
                                         "/bin/btop"))
                               (capabilities
                                "cap_perfmon=ep"))
                             %default-privileged-programs))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   services-list)

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
  ;; Root is LUKS on nvme0n1p3. GRUB unlocks it itself (kernels live in
  ;; /gnu/store), so it must be LUKS1 or LUKS2 with PBKDF2, and Guix
  ;; finds it by UUID. Create it at install with this fixed UUID:
  ;;   cryptsetup luksFormat --type luks2 --pbkdf pbkdf2 \
  ;;     --uuid 93461f69-f18d-4a72-a3be-f0f22729930f /dev/nvme0n1p3
  ;; (nvme0n1p2, the old 2G /boot, is not used.)
  (mapped-devices (list (mapped-device
                          (source (uuid
                                   "93461f69-f18d-4a72-a3be-f0f22729930f"))
                          (target "cryptroot")
                          (type luks-device-mapping))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/")
                         (device "/dev/mapper/cryptroot")
                         (type "btrfs")
                         (flags '(no-atime))
                         (options
                          "compress=zstd:3,space_cache=v2,commit=120")
                         (dependencies mapped-devices))
                        (file-system
                          (mount-point "/boot/efi")
                          (device (uuid "8675-B6E2"
                                        'fat32))
                          (type "vfat")) %base-file-systems)))
