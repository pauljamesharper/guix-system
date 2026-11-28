# The desktop: mango with the mangobutter bar, as the dotfiles set it up on
# Debian. greetd + tuigreet log in (Debian: SDDM), the login password
# unlocks gnome-keyring and its ssh agent (gcr: $XDG_RUNTIME_DIR/gcr/ssh).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  local = import ../../pkgs { inherit pkgs; };

  # Debian's mango-session (the mangowc package's wrapper): the session
  # environment from ~/.config/mango/env (dotfiles), then mango
  mango-session = pkgs.writeShellScriptBin "mango-session" ''
    env_file="''${XDG_CONFIG_HOME:-$HOME/.config}/mango/env"
    if [ -r "$env_file" ]; then
        if sh -n "$env_file" 2>/dev/null; then
            set -a
            . "$env_file"
            set +a
        else
            echo "mango-session: syntax error in $env_file, ignoring it" >&2
        fi
    fi
    exec ${config.programs.mango.package}/bin/mango "$@"
  '';
in
{
  programs.mango.enable = true; # mango, portals (wlr, gtk), the session entry

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = lib.concatStringsSep " " [
        "${pkgs.tuigreet}/bin/tuigreet"
        "--time --remember --asterisks"
        "--greeting 'Welcome to mango'"
        "--cmd ${mango-session}/bin/mango-session"
      ];
      user = "greeter";
    };
  };

  services.gnome.gnome-keyring.enable = true; # and gcr-ssh-agent with it
  security.pam.services.greetd.enableGnomeKeyring = true;
  # quickshell-lock authenticates against PAM "login"
  security.pam.services.login.enableGnomeKeyring = true;
  security.polkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true; # ALSA apps (cliamp, amixer) through PipeWire
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.upower.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  programs.dconf.enable = true;
  programs.xfconf.enable = true;
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # the bar, the wallpaper picker and its themes; the GTK template and
  # icons in /run/current-system/sw/share, where mangobutter's gtk-theme
  # looks; the Pomodoro chime
  environment.systemPackages =
    (with pkgs; [
      mango-session
      quickshell
      awww
      rofi
      dunst
      libnotify
      brightnessctl
      wlsunset
      qrencode
      grim
      slurp
      swappy
      wl-clipboard
      cliphist
      wlr-randr
      swayidle
      wlopm
      xrandr
      nwg-look
      xsettingsd
      pamixer
      pulsemixer
      playerctl
      pavucontrol
      networkmanagerapplet
      xdg-utils
      xdg-user-dirs
      gsettings-desktop-schemas
      adwaita-icon-theme
      hicolor-icon-theme
      sound-theme-freedesktop
      polkit_gnome
      kitty
      geany
      fastfetch
      btop
    ])
    ++ [
      local.orchis-nord-template
      local.colloid-icon-theme-butter
      local.lxpolkit
      inputs.butterpal.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.butterview.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  fonts.packages = with pkgs; [
    noto-fonts # Khmer and the rest
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    khmeros
    tlwg # Thai
    ipafont # Japanese
    amiri # Arabic
    font-awesome
    dejavu_fonts
    liberation_ttf
    nerd-fonts.roboto-mono # the bar, kitty, rofi
    nerd-fonts.sauce-code-pro # geany
    nerd-fonts.symbols-only
  ];

  # Steam from nixpkgs, with Proton-GE beside Valve's Proton and
  # Protontricks; controllers and VR headsets (steam-hardware), GameMode
  # (gamemoderun %command%), gamescope (gamescope -f -- %command%) and
  # MangoHud (mangohud %command%, in modules/home)
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
  };
  hardware.steam-hardware.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # LocalSend, with its port (53317) open on the firewall
  programs.localsend.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
