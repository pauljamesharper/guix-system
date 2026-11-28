# crash-watch — "Process crashed" notifications, after Omarchy's crash capture
# (https://omarchy.org/manual/ai/). Follows the journal for systemd-coredump's
# crash records of this user's programs and shows a notification; its
# Diagnose button runs crash-diagnose, which hands the crash to Claude Code.
# Run by crash-watch.service (modules/home). Nothing leaves the machine.
#   CRASH_IGNORE           regex of program names never to announce
#   CRASH_DEDUPE_SECONDS   one notification per program per this long (60)
#   crash-mute <program>   silence one program; crash-mute alone lists them
MUTED="${XDG_STATE_HOME:-$HOME/.local/state}/crash-watch/muted"
DEDUPE=${CRASH_DEDUPE_SECONDS:-60}
me=$(id -u)
declare -A last

# MESSAGE_ID of systemd-coredump's "Process … dumped core" entry; -n 0: only
# crashes from now on, so a restart doesn't announce old ones again
journalctl --user -f -n 0 -o json MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1 2>/dev/null |
while IFS= read -r line; do
    IFS=$'\t' read -r uid pid comm exe sig < <(jq -r '[.COREDUMP_UID // ._UID // "", .COREDUMP_PID // "", .COREDUMP_COMM // "", .COREDUMP_EXE // "", .COREDUMP_SIGNAL_NAME // .COREDUMP_SIGNAL // ""] | @tsv' <<<"$line")
    [ "$uid" = "$me" ] || continue
    # a Nix program's binary is often a wrapper's .foo-wrapped: name it foo
    name=${exe##*/}; name=${name:-$comm}; name=${name##*/}
    name=${name#.}; name=${name%-wrapped}
    [ -n "$name" ] || continue
    case "$name" in crash-*) continue ;; esac
    [ -n "${CRASH_IGNORE:-}" ] && [[ $name =~ $CRASH_IGNORE ]] && continue
    [ -e "$MUTED/$name" ] && continue
    now=$(date +%s)
    (( now - ${last[$name]:-0} < DEDUPE )) && continue
    last[$name]=$now
    # waits for the click in the background, so the next crash isn't held up
    (
        action=$(notify-send -u critical -a "Crash" -i dialog-error \
            -A diagnose="Diagnose with Claude" -A mute="Mute $name" --wait \
            "$name crashed" "Signal ${sig:-?}, PID $pid. Diagnose finds out why and whether it's worth reporting.")
        case "$action" in
            diagnose) exec crash-diagnose "$pid" "$comm" "$exe" "$sig" ;;
            mute) exec crash-mute "$name" on ;;
        esac
    ) &
done
