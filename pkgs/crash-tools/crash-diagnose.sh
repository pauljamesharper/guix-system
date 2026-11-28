# crash-diagnose PID [COMM EXE SIGNAL] — hand a crash to Claude Code, after
# Omarchy's `omarchy agent crash`. Opens Claude Code in its own terminal with
# what systemd-coredump recorded and its diagnose-crash skill (the dotfiles'
# claude package). Any PID from `coredumpctl list` works.
pid=${1:?usage: crash-diagnose PID [COMM EXE SIGNAL]  (PIDs: coredumpctl list)}
[[ $pid =~ ^[0-9]+$ ]] || { echo "crash-diagnose: PID must be a number" >&2; exit 2; }
comm=${2:-unknown}; exe=${3:-unknown}; sig=${4:-unknown}
when=$(coredumpctl list "$pid" --no-pager --no-legend 2>/dev/null | tail -n 1 | cut -d' ' -f1-4)
prompt="A program crashed on this NixOS machine. What systemd-coredump recorded:
- process: $comm
- PID: $pid
- binary: $exe
- signal: $sig
- time: ${when:-unknown}

Use the diagnose-crash skill: work out why it crashed, and whether it is a bug worth reporting (to nixpkgs or upstream). Don't change anything on the system, and don't file anything without asking me."
# an interactive shell, so claude (a mise tool) is on PATH as in a terminal
# shellcheck disable=SC2016  # $1 is for the inner bash
exec kitty --class agent --title "Crash: $comm" bash -ic 'cd ~ && claude "$1"' crash-diagnose "$prompt"
