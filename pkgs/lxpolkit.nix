# mango/autostart.conf starts the polkit agent by its Debian name; here
# that's polkit-gnome's agent.
{ writeShellScriptBin, polkit_gnome }:

writeShellScriptBin "lxpolkit" ''
  exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
''
