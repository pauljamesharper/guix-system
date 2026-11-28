# The Flatpak apps the Debian installs have (install-packages.sh 'flatpak'
# and 'steam'), system-wide from Flathub. nix-flatpak installs them at
# activation and removes ones dropped from this list.
{ pkgs, ... }:
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
      "io.github.kolunmi.Bazaar" # Flathub app store
      "com.discordapp.Discord"
      "org.telegram.desktop"
      "io.github.focustimerhq.FocusTimer" # the bar's Focus Timer pill
      "org.localsend.localsend_app"
      "org.mozilla.thunderbird"
      "net.ankiweb.Anki"
      # Steam with its own 32-bit libraries and Mesa, Proton-GE beside
      # Valve's Proton, Protontricks
      "com.valvesoftware.Steam"
      "com.valvesoftware.Steam.CompatibilityTool.Proton-GE"
      "com.github.Matoking.protontricks"
    ];
    # Protontricks needs Steam's library in the Flatpak's data folder
    overrides."com.github.Matoking.protontricks".Context.filesystems = [
      "/home/pharper/.var/app/com.valvesoftware.Steam"
    ];
  };

  # MangoHud and gamescope Vulkan layers for the runtime Steam runs on
  # (mangohud %command%, gamescope -f -- %command%): the branch depends on
  # Steam's runtime, so they are looked up after nix-flatpak's install.
  # Started by that install, not by multi-user.target: nix-flatpak's unit
  # runs after multi-user.target, so hanging this off it made a cycle and
  # systemd dropped the install job (gUn never got its apps)
  systemd.services.flatpak-steam-layers = {
    description = "Vulkan layers (MangoHud, gamescope) for Flatpak Steam";
    after = [ "flatpak-managed-install.service" ];
    wantedBy = [ "flatpak-managed-install.service" ];
    serviceConfig.Type = "oneshot";
    path = [
      pkgs.flatpak
      pkgs.gnused
    ];
    script = ''
      branch=$(flatpak info com.valvesoftware.Steam 2>/dev/null | sed -n 's|.*Runtime: .*/||p')
      [ -n "$branch" ] || { echo "Steam isn't installed yet"; exit 0; }
      flatpak install -y --noninteractive flathub \
          "org.freedesktop.Platform.VulkanLayer.MangoHud//$branch" \
          "org.freedesktop.Platform.VulkanLayer.gamescope//$branch"
    '';
  };
}
