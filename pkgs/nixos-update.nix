# nixos-update: what `apt update && apt upgrade` was. The bar's Updates
# pill and the launcher's "Check for updates" run it.
#   nixos-update           update the flake's inputs, rebuild and switch
#   nixos-update --check   update the inputs, build, and show what would change
{
  writeShellApplication,
  nix,
  nixos-rebuild,
  nvd,
  git,
}:

writeShellApplication {
  name = "nixos-update";
  runtimeInputs = [
    nix
    nixos-rebuild
    nvd
    git
  ];
  text = ''
    repo="''${NIXOS_CONFIG_REPO:-/etc/nixos}"
    cd "$repo"
    nix flake update --flake "$repo"
    nixos-rebuild build --flake "$repo"
    nvd diff /run/current-system ./result
    rm -f result
    if [ "''${1:-}" = --check ]; then
        echo "run nixos-update to switch to these (flake.lock is updated; commit it after)"
        exit 0
    fi
    sudo nixos-rebuild switch --flake "$repo"
    echo "updated; commit flake.lock in $repo"
  '';
}
