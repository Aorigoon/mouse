#!/usr/bin/env bash
# Mousify input-permission fix — pkexec ke zariye ROOT ke taur par chalta hai.
# polkit (Fedora ka native dialog) khud sudo password maangta hai; password
# hamare code ke paas aata hi nahi.
#
# Kya karta hai:
#   1) /dev/uinput ke liye udev rule (MODE 0666 — personal machine par standard)
#   2) udev rules reload + trigger (turant apply, reboot ki zarurat nahi)
#   3) invoking user ko input group me add (extra, harmless)

set -euo pipefail

RULE_PATH=/etc/udev/rules.d/80-mousify-uinput.rules

cat > "$RULE_PATH" <<'EOF'
KERNEL=="uinput", MODE="0666"
EOF

udevadm control --reload-rules
udevadm trigger
udevadm settle

# invoking user ko input group me daalo (pkexec UID se)
if [[ -n "${PKEXEC_UID:-}" ]]; then
  TARGET_USER="$(id -un "$PKEXEC_UID")"
  usermod -aG input "$TARGET_USER" || true
fi

# verify
if [[ "$(stat -c %a /dev/uinput)" != "666" ]]; then
  echo "udev rule applied but /dev/uinput mode did not update" >&2
  exit 1
fi

echo "PERMISSIONS_OK"
