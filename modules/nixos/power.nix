# Debian's 'hardware' section: on a laptop TLP (with battery charge
# thresholds; it replaces power-profiles-daemon) and, on Intel, thermald;
# otherwise power-profiles-daemon, which the bar's power menu uses. And the
# fingerprint reader, where there is one.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my;
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.laptop {
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        # keep the battery between 75 and 80 % on mains power;
        # `sudo tlp fullcharge` before a trip
        settings = {
          START_CHARGE_THRESH_BAT0 = 75;
          STOP_CHARGE_THRESH_BAT0 = 80;
          START_CHARGE_THRESH_BAT1 = 75;
          STOP_CHARGE_THRESH_BAT1 = 80;
        };
      };
      services.thermald.enable = cfg.cpu == "intel";
      environment.systemPackages = [ pkgs.powertop ];
    })
    (lib.mkIf (!cfg.laptop) {
      services.power-profiles-daemon.enable = true;
    })
    # Debian's HW_FINGERPRINT_PACKAGES (fprintd + libpam-fprintd)
    (lib.mkIf cfg.fingerprint {
      services.fprintd.enable = true; # with enablePam: fprintAuth for every PAM service
      security.pam.services.greetd.fprintAuth = false;
    })
  ];
}
