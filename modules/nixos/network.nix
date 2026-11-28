# Networking as debian/install-packages.sh 'dns' and 'protonvpn' set it up:
# Cloudflare's malware-blocking 1.1.1.2 / 1.0.0.2 on every network through
# systemd-resolved; Wi-Fi and wired never add their DHCP servers; a VPN's
# own servers while it is up (its link claims ~.). Proton VPN's own app.
{ pkgs, ... }:
let
  # the Debian dispatcher script, /etc/NetworkManager/dispatcher.d/90-no-dhcp-dns
  noDhcpDns = pkgs.writeShellScript "90-no-dhcp-dns" ''
    # Wi-Fi and wired connections: no DNS from DHCP or router adverts, so
    # systemd-resolved's global servers are used
    nmcli=${pkgs.networkmanager}/bin/nmcli
    [ "$2" = up ] || exit 0
    [ -n "$CONNECTION_UUID" ] || exit 0
    case "$($nmcli -g connection.type connection show "$CONNECTION_UUID")" in
        802-11-wireless|802-3-ethernet) ;;
        *) exit 0 ;;
    esac
    [ "$($nmcli -g ipv4.ignore-auto-dns,ipv6.ignore-auto-dns connection show "$CONNECTION_UUID")" = "yes
    yes" ] && exit 0
    $nmcli connection modify "$CONNECTION_UUID" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes
    $nmcli device reapply "$DEVICE_IFACE"
  '';
in
{
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
    plugins = [ pkgs.networkmanager-openvpn ];
    dispatcherScripts = [ { source = noDhcpDns; } ];
  };

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = "";
  };
  # resolved's global servers (no routing domain: they answer whenever no
  # link claims a query)
  networking.nameservers = [
    "1.1.1.2"
    "1.0.0.2"
  ];

  networking.firewall = {
    enable = true;
    # LocalSend (Flatpak); ssh and mDNS open themselves
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
    # WireGuard VPNs (Proton) need loose reverse-path filtering
    checkReversePath = "loose";
  };

  # Proton VPN's official app: protonvpn-app (mango/autostart.conf)
  environment.systemPackages = [ pkgs.proton-vpn ];
}
