# Crash capture, after Omarchy's (https://omarchy.org/manual/ai/): crash-watch
# (run by crash-watch.service, modules/home) notifies when one of your
# programs crashes, and its Diagnose button opens Claude Code on it with the
# diagnose-crash skill (the dotfiles' claude package):
#   crash-watch                 the watcher (the service runs it)
#   crash-diagnose PID          hand any crash from `coredumpctl list` to Claude
#   crash-capture on|off        all the notifications
#   crash-mute PROGRAM [off]    one program's notifications
# systemd-coredump keeps the cores (NixOS's default) and
# nixseparatedebuginfod2 (modules/nixos/base.nix) gdb's symbols.
{
  lib,
  symlinkJoin,
  writeShellApplication,
  jq,
  libnotify,
  systemd,
  coreutils,
  kitty,
  bashInteractive,
}:
let
  tool =
    name: runtimeInputs:
    writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./${name}.sh;
      # crash-watch's notifications wait for a click in the background,
      # where pipefail and errexit would end them early
      bashOptions = [ "nounset" ];
    };
in
symlinkJoin {
  name = "crash-tools";
  paths = [
    (tool "crash-watch" [
      jq
      libnotify
      systemd
      coreutils
    ])
    (tool "crash-diagnose" [
      systemd
      coreutils
      kitty
      bashInteractive
    ])
    (tool "crash-capture" [
      libnotify
      systemd
      coreutils
    ])
    (tool "crash-mute" [ coreutils ])
  ];
  meta.description = "Crash notifications with a Diagnose-with-Claude button";
}
