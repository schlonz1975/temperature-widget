#!/usr/bin/env bash
# Install / update / remove the plasmoid with kpackagetool6.
set -euo pipefail

ID="com.jens.hwmonitor"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/package"

usage() { echo "usage: $0 [install|uninstall|test|restart]  (default: install)"; }

command -v kpackagetool6 >/dev/null || { echo "kpackagetool6 not found (install kf6-kpackage)" >&2; exit 1; }

case "${1:-install}" in
  install)
    if kpackagetool6 -t Plasma/Applet -l 2>/dev/null | grep -qx "$ID"; then
      kpackagetool6 -t Plasma/Applet -u "$DIR"
    else
      kpackagetool6 -t Plasma/Applet -i "$DIR"
    fi
    echo "Done. Right-click desktop/panel -> Add Widgets -> 'Hardware Temps & Fans'."
    echo "If the widget does not show or is stale: $0 restart"
    ;;
  uninstall)
    kpackagetool6 -t Plasma/Applet -r "$ID"
    ;;
  test)
    exec plasmawindowed "$ID"
    ;;
  restart)
    kquitapp6 plasmashell || true
    sleep 1
    nohup kstart plasmashell >/dev/null 2>&1 &
    ;;
  *) usage; exit 1 ;;
esac
