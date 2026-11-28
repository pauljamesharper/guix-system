# pharper's home, via Home Manager. The dotfiles (~/dotfiles, stow) stay
# the source of every config file, editable in place as on Debian: Home
# Manager installs the programs debian/install-packages.sh installs with
# apt, then scripts/home-activate stows the dotfiles, enables their user
# units and sets up the mangobutter files.
{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.pharper = import ./pharper.nix;
  };

  # GObject typelibs for `superwhisper doctor` and the like from a shell
  # (its service gets them through a drop-in, pharper.nix)
  environment.sessionVariables.GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
}
