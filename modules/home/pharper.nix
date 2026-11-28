# pharper's Home Manager configuration (imported by ./default.nix).
{ pkgs, lib, ... }:
let
  local = import ../../pkgs { inherit pkgs; };

  wallpaper = pkgs.fetchurl {
    url = "https://justaguy.dev/butter/wallpapers/raw/branch/main/mangobutter-journey.png";
    hash = "sha256-VBeVTxL0JEtlAomoAmJq+Cajp6QJXUw4Sjeuj3D+A+g=";
  };
in
{
  home.stateVersion = "26.05";

  # APT_PACKAGES and BACKPORTS_PACKAGES (the desktop's own programs are
  # system packages, modules/nixos/desktop.nix). Claude Code, gh, uv,
  # cliamp, etesync-dav and the pipx apps (khal, khard, vdirsyncer,
  # beancount, fava, yt-dlp) are mise tools, as on Debian.
  home.packages = with pkgs; [
    # build tools
    gcc
    gnumake
    cmake
    pkg-config
    # core cli (git: programs.git below)
    git-lfs
    stow
    pass
    tmux
    gnupg
    unzip
    zip
    p7zip
    jq
    ripgrep
    fd
    bat
    tree
    htop
    starship
    lsd
    micro
    # Omarchy's shell tools
    fzf
    zoxide
    eza
    bash-completion
    tealdeer
    lazygit
    gum
    ruby
    # the shell functions (rsw, format-drive)
    rsync
    inotify-tools
    file
    lsof
    strace
    gdb # crash-diagnose's backtraces
    local.crash-tools # crash-diagnose, crash-capture, crash-mute (below)
    mise
    pipx # python3 is the system's (with PyGObject, superwhisper.nix)
    # desktop programs
    firefox
    emacs-pgtk
    libreoffice
    nautilus
    zenity # sudo-askpass
    alsa-utils
    mpv
    yazi
    # screenrecord, capture-menu, transcode, capture-text
    wf-recorder
    zbar
    v4l-utils
    imagemagick
    ffmpeg
    hyprpicker
    (tesseract.override {
      enableLanguages = [
        "eng"
        "khm"
      ];
    })
    # Emacs spell checking (en_AU)
    hunspell
    hunspellDicts.en_AU
    # spd-say
    speechd
    espeak-ng
    mangohud # its config is the 'mangohud' stow package
    # desktop apps (from nixpkgs rather than Flathub; see modules/nixos/flatpak.nix)
    discord
    telegram-desktop
    thunderbird
    anki
    bazaar # Flathub store, for what nixpkgs lacks
  ];

  # the dotfiles, the user units and mangobutter (scripts/home-activate)
  home.activation.dotfiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    (
      export PATH=${
      lib.makeBinPath (
        with pkgs;
        [
          stow
          coreutils
          findutils
          gnused
          gawk
          gnugrep
          patch
          diffutils
          glib # gsettings
          dconf
        ]
      )
    }:$PATH
      export MANGOBUTTER=${local.mangobutter}
      export DEFAULT_WALLPAPER=${wallpaper}
      run ${pkgs.bash}/bin/bash ${../../scripts/home-activate}
    )
  '';

  # Superwhisper's own unit (its installer writes it) finds the GObject
  # typelibs its Python helpers load
  xdg.configFile."systemd/user/superwhisper.service.d/nixos.conf".text = ''
    [Service]
    Environment=GI_TYPELIB_PATH=/run/current-system/sw/lib/girepository-1.0
  '';

  # Omarchy's themes (pkgs/omarchy-themes.nix): their palettes beside
  # mangobutter's own in butter-themes, their previews for the theme picker
  # (Super+Shift+T), and their wallpapers linked one by one into the shared
  # wallpaper folder, beside your own (the Backgrounds tab, Super+Shift+W,
  # shows the theme's).
  xdg.dataFile."butter-themes/omarchy.conf".source =
    "${local.omarchy-themes}/share/butter-themes/omarchy.conf";
  xdg.dataFile."omarchy-themes".source = "${local.omarchy-themes}/share/omarchy-themes";
  xdg.dataFile."wallpapers" = {
    source = "${local.omarchy-themes}/share/wallpapers";
    recursive = true;
  };

  # Weekly update check: nixos-update --check, but on a copy of the repo so
  # /etc/nixos's flake.lock is left alone, then a notification when the
  # build differs from the running system. Applying stays a choice: the
  # bar's Updates pill (nixos-update). The build is cached, so the switch
  # afterwards is quick.
  systemd.user.services.nixos-update-check = {
    Unit.Description = "Check for NixOS updates";
    Unit.ConditionACPower = true;
    Service = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
      ExecStart = toString (
        pkgs.writeShellScript "nixos-update-check" ''
          set -eu
          export PATH=${
            lib.makeBinPath [
              pkgs.nix
              pkgs.nvd
              pkgs.git
              pkgs.libnotify
              pkgs.coreutils
              pkgs.gnugrep
            ]
          }
          host=$(cat /proc/sys/kernel/hostname)
          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT
          cp -a /etc/nixos "$tmp/repo"
          nix flake update --flake "$tmp/repo"
          new=$(nix build --no-link --print-out-paths \
            "$tmp/repo#nixosConfigurations.$host.config.system.build.toplevel")
          if [ "$new" = "$(readlink -f /run/current-system)" ]; then
            echo "up to date"
            exit 0
          fi
          diff=$(nvd diff /run/current-system "$new")
          echo "$diff"
          # version changes only: a config edit not switched to yet also
          # makes the build differ, and isn't an update
          n=$(printf '%s\n' "$diff" | grep -c '^\[U' || true)
          [ "$n" -gt 0 ] || exit 0
          notify-send -a "NixOS" -i system-software-update "NixOS updates ready" \
            "$n package updates. Run them from the bar's Updates pill (nixos-update)."
        ''
      );
    };
  };
  systemd.user.timers.nixos-update-check = {
    Unit.Description = "Weekly NixOS update check";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true; # catches up after the laptop was off or asleep
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Crash notifications, after Omarchy (pkgs/crash-tools): a crash of one of
  # your programs shows "Diagnose with Claude" and "Mute". crash-capture
  # off|on turns them off and on (the flag file stops the unit starting).
  systemd.user.services.crash-watch = {
    Unit = {
      Description = "Crash notifications (systemd-coredump records, Diagnose with Claude)";
      ConditionPathExists = "!%h/.local/state/crash-watch/off";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${local.crash-tools}/bin/crash-watch";
      # its Diagnose and Mute buttons run these by name
      Environment = "PATH=${local.crash-tools}/bin:/etc/profiles/per-user/pharper/bin:/run/current-system/sw/bin";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # git identity
  programs.git = {
    enable = true;
    settings.user = {
      name = "Paul Harper";
      email = "harper.paul.j@gmail.com";
    };
  };
}
