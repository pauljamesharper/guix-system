# crash-capture [on|off|toggle|status] — turn crash-watch's notifications on
# or off, after Omarchy's crash-capture toggle. Off leaves crashes recorded
# (coredumpctl list) and crash-diagnose working by hand.
flag="${XDG_STATE_HOME:-$HOME/.local/state}/crash-watch/off"
case "${1:-toggle}" in
    status) [ -e "$flag" ] && echo off || echo on; exit 0 ;;
    toggle) if [ -e "$flag" ]; then set -- on; else set -- off; fi ;;
esac
mkdir -p "${flag%/*}"
case "$1" in
    off) touch "$flag"; systemctl --user stop crash-watch.service; notify-send -a Crash "Crash capture off" "Crashes are still recorded: coredumpctl list" ;;
    on) rm -f "$flag"; systemctl --user start crash-watch.service; notify-send -a Crash "Crash capture on" "You'll be told when a program crashes" ;;
    *) echo "usage: crash-capture [on|off|toggle|status]" >&2; exit 2 ;;
esac
