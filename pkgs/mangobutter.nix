# The mangobutter setup (https://justaguy.dev/butter/mango): the Quickshell
# bar, lock screen and network panel, the scripts mango's keys run, and the
# dunst, rofi, kitty and swappy configs. On Debian its install.sh copies
# share/ to ~/.local/share/mango; here scripts/home-activate does, then
# runs ~/dotfiles/mango-shell/apply.sh for the bar changes.
{ stdenvNoCC, fetchgit }:

stdenvNoCC.mkDerivation {
  pname = "mangobutter";
  # the commit gUn's Debian install runs, which mango-shell's patches fit
  version = "0-unstable-2026-11-24";

  src = fetchgit {
    url = "https://justaguy.dev/butter/mango";
    rev = "c09a61a9369855dca6baf5952aef70c3b8884604";
    hash = "sha256-H2ulygOURY0KKN5eiCSRHYsXwJ/KnRuU8LUUB70BZaM=";
  };

  postPatch = ''
    # the GTK template, icons and sounds are in the system profile
    substituteInPlace share/scripts/gtk-theme \
      --replace-fail /usr/share/themes /run/current-system/sw/share/themes \
      --replace-fail /usr/share/icons /run/current-system/sw/share/icons
    substituteInPlace share/quickshell/Pomodoro.qml \
      --replace-fail /usr/share/sounds /run/current-system/sw/share/sounds
    substituteInPlace share/dunst/dunstrc \
      --replace-fail /usr/bin/rofi rofi \
      --replace-fail /usr/bin/xdg-open xdg-open

    # updates: nixos-update (flake update + rebuild), not apt
    substituteInPlace share/quickshell/Updates.qml \
      --replace-fail "sudo apt update && sudo apt full-upgrade; " "nixos-update; "
    substituteInPlace share/quickshell/LauncherPopup.qml share/quickshell/Commands.qml \
      --replace-fail "sudo apt update && apt list --upgradable; " "nixos-update --check; "
    substituteInPlace share/quickshell/UpdateCount.qml \
      --replace-fail "apt-get -s -o Debug::NoLocking=1 dist-upgrade 2>/dev/null | grep -c '^Inst'" "echo 0"
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mango-setup
    cp -r share $out/share/mango
    cp -r config state $out/share/mango-setup/
    chmod +x $out/share/mango/scripts/*
    runHook postInstall
  '';

  meta = {
    description = "mango desktop setup: Quickshell bar, scripts and themes";
    homepage = "https://justaguy.dev/butter/mango";
  };
}
