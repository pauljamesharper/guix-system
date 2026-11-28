# Packages this config adds: the mangobutter desktop's files and themes,
# and small shims. `nix build .#mangobutter` builds one on its own.
{ pkgs }:
let
  themes = pkgs.callPackage ./butterrepo-themes.nix { };
in
{
  mangobutter = pkgs.callPackage ./mangobutter.nix { };
  inherit (themes) orchis-nord-template colloid-icon-theme-butter;
  lxpolkit = pkgs.callPackage ./lxpolkit.nix { };
  nixos-update = pkgs.callPackage ./nixos-update.nix { };
  omarchy-themes = pkgs.callPackage ./omarchy-themes.nix { };
}
