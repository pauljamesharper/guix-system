# Superwhisper (voice dictation). The vendor's per-user install, as on
# Debian: after the first login run
#   curl -fsSL --proto '=https' https://tux.superwhisper.com/install.sh | SW_SKIP_PACKAGES=1 sh
# It puts the app in ~/.local/share/superwhisper with its own user service
# and update timer, and updates itself. Its binaries are prebuilt for
# ordinary distributions: nix-ld (base.nix) gives them a loader and the
# libraries; here are the programs and Python modules it runs (Debian's
# SUPERWHISPER_PACKAGES). The user-service drop-in (modules/home) hands it
# the GObject typelib path.
{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [
    ps.pygobject3
    ps.pycairo
  ]);
in
{
  environment.systemPackages = with pkgs; [
    python # its doctor, update and paste helpers (GTK 4, AT-SPI over GI)
    pipewire # pw-record, pw-cat
    pulseaudio # pactl (only the tools; PipeWire is the server)
    libnotify
    wl-clipboard
    wtype # types the paste on mango
    ffmpeg
    minisign # checks its updates' signatures
    librsvg
    vulkan-tools

    # its typelibs, linked into /run/current-system/sw/lib/girepository-1.0
    gtk4
    gtk4-layer-shell
    at-spi2-core
    gobject-introspection
    # .out: the typelibs (GLib, GObject, Gio, Pango, PangoCairo) live in
    # these outputs; plain glib/pango install only their -bin output
    glib.out
    pango.out
    gdk-pixbuf
    harfbuzz
    graphene
  ];
  environment.pathsToLink = [ "/lib/girepository-1.0" ];
}
