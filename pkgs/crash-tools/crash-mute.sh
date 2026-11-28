# crash-mute [PROGRAM [on|off|toggle]] — stop (or restart) crash-watch's
# notifications for one program; with no program, list the muted ones. It
# only hides the reminder: the program still crashes and is still recorded
# (coredumpctl list). crash-capture off|on turns all of it off or on.
dir="${XDG_STATE_HOME:-$HOME/.local/state}/crash-watch/muted"
if [ $# -eq 0 ]; then
    if [ -d "$dir" ] && [ -n "$(ls -A "$dir")" ]; then ls -1 "$dir"; else echo "No programs muted. Crashes all notify."; fi
    exit 0
fi
[ "$1" = -- ] && shift
# a path or a Nix wrapper (/nix/store/…/.foo-wrapped) names the program foo
name=${1##*/}; name=${name#.}; name=${name%-wrapped}
action=${2:-on}
mkdir -p "$dir"
case "$action" in
    on) touch "$dir/$name"; echo "muted: $name" ;;
    off) rm -f "$dir/$name"; echo "unmuted: $name" ;;
    toggle) if [ -e "$dir/$name" ]; then rm -f "$dir/$name"; echo "unmuted: $name"; else touch "$dir/$name"; echo "muted: $name"; fi ;;
    *) echo "usage: crash-mute [PROGRAM [on|off|toggle]]" >&2; exit 2 ;;
esac
