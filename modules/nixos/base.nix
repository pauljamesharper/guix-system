# The system both machines share: boot, nix, locale, the user, firmware,
# memory, ssh and the bits of FHS that downloaded binaries expect.
{ pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nixpkgs.config.allowUnfree = true;

  # The NixOS default kernel; generations in the boot menu take the place
  # of Timeshift + grub-btrfs snapshots
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 20;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # the LUKS passphrase and boot in Plymouth's bgrt splash (the firmware's
  # logo, as on Debian)
  boot.initrd.systemd.enable = true;
  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };
  boot.kernelParams = [
    "quiet"
    "splash"
  ];

  time.timeZone = "Asia/Phnom_Penh";
  i18n.defaultLocale = "en_AU.UTF-8";
  console.keyMap = "us";

  users.users.pharper = {
    isNormalUser = true;
    description = "Paul Harper";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "kvm"
      "libvirtd"
    ];
  };

  # firmware, microcode (hardware.nix), firmware updates: fwupdmgr update
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
  services.fstrim.enable = true;

  # compressed swap in RAM: Debian's zram0, half the memory
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # ssh between gUn and alteredcarbon (keys only); host.local names
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # crash capture (crash-watch, crash-diagnose): systemd-coredump keeps
  # core dumps (on by default); this serves debug symbols to gdb
  services.nixseparatedebuginfod2.enable = true;

  # Prebuilt binaries (mise's Claude Code, cliamp, etesync-dav; Superwhisper)
  # find a loader and these libraries, as on Debian
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++, libgcc_s, libgomp, libatomic
      zlib
      zstd
      xz
      bzip2
      brotli
      lzo
      alsa-lib
      dbus
      glib
      gtk4
      gtk4-layer-shell
      at-spi2-core
      cairo
      pango
      harfbuzz
      graphite2
      fribidi
      libthai
      libdatrie
      gdk-pixbuf
      graphene
      libepoxy
      fontconfig
      freetype
      expat
      libpng
      libjpeg
      libtiff
      libwebp
      libdeflate
      lerc
      jbigkit
      pcre2
      libffi
      libselinux
      util-linux.lib # libmount, libblkid
      libcloudproviders
      vulkan-loader
      libxkbcommon
      wayland
      pixman
      libx11
      libxext
      libxi
      libxcursor
      libxdamage
      libxfixes
      libxrandr
      libxinerama
      libxrender
      libxcb
      libxau
      libxdmcp
    ];
  };

  # root's git trusts the repo pharper owns, so `sudo nixos-rebuild` works
  programs.git = {
    enable = true;
    config.safe.directory = [ "/etc/nixos" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    pciutils
    usbutils
    lm_sensors
    acpi
    btrfs-progs
    cryptsetup
    dosfstools
    exfatprogs
    parted
    (pkgs.callPackage ../../pkgs/nixos-update.nix { })
  ];

  # The release this config was first installed with; leave it as is
  system.stateVersion = "26.05";
}
