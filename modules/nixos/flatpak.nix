# Flatpak apps, system-wide from Flathub: only what nixpkgs doesn't have.
# Everything else (Steam, Discord, Telegram, Thunderbird, Anki, LocalSend,
# Bazaar) comes from nixpkgs: desktop.nix and modules/home/pharper.nix.
# nix-flatpak installs these at activation and removes ones dropped from
# this list.
{ ... }:
{
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      # the bar's Focus Timer pill talks to it over D-Bus
      # (io.github.focustimerhq.FocusTimer); nixpkgs only has the older
      # gnome-pomodoro, under another name
      "io.github.focustimerhq.FocusTimer"
    ];
  };
}
