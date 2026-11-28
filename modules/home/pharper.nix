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

  # git identity
  programs.git = {
    enable = true;
    settings.user = {
      name = "Paul Harper";
      email = "harper.paul.j@gmail.com";
    };
  };
}
