#!/usr/bin/env bash
# aspersum idle timeouts. Lock/unlock/lock-before-sleep are handled by
# systemd-lock-handler + swaylock.service (systemd targets); this only decides
# WHEN to dim, blank, and suspend on inactivity.
set -euo pipefail

on_ac() {
  # true if any AC adapter (ADP*/AC*) reports online == 1
  for f in /sys/class/power_supply/A*/online; do
    [ -r "$f" ] && [ "$(cat "$f")" = 1 ] && return 0
  done
  return 1
}

suspend_if_battery() {
  # On AC never sleep (monitors already off); on battery suspend, then hibernate
  # after systemd's HibernateDelaySec (suspend-then-hibernate).
  on_ac || systemctl suspend-then-hibernate
}

case "${1:-run}" in
  suspend) suspend_if_battery ;;
  run)
    # "$0 suspend" re-invokes this script by absolute path (systemd starts it via
    # its store path) so the suspend branch resolves without needing it on PATH.
    exec swayidle -w \
      timeout 590 'chayang -d 10 && loginctl lock-session' \
      timeout 660 'niri msg action power-off-monitors' \
      timeout 900 "$0 suspend"
    ;;
  *)
    echo "unknown subcommand: $1" >&2
    exit 1
    ;;
esac
