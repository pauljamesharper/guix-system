{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./options.nix
    ./disko.nix
    ./base.nix
    ./desktop.nix
    ./network.nix
    ./power.nix
    ./virtualisation.nix
    ./flatpak.nix
    ./superwhisper.nix
    ../home
  ];
}
