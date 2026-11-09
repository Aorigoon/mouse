#!/usr/bin/env bash
# Mousify server installer — venv + systemd --user service setup karta hai.
#
#   bash install.sh
#
# Note: workspace external (NTFS-style) mount par ho sakta hai jahan venv ke
# symlinks break ho jate hain — is liye code + venv ~/.local/share/mousify/
# (native filesystem) me install hote hain. Workspace source of truth rehta
# hai; code change ke baad ye script dobara chala do.

set -euo pipefail

SERVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.local/share/mousify"
VENV="$DEST/venv"

echo "==> Mousify server install"
echo "    source : $SERVER_DIR"
echo "    dest   : $DEST"

mkdir -p "$DEST"

# 1) code copy (venv exclude)
rm -rf "$DEST/server" "$DEST/tools"
mkdir -p "$DEST"
cp -a "$SERVER_DIR" "$DEST/server"
if [[ -d "$SERVER_DIR/tools" ]]; then
  mkdir -p "$DEST/tools"
  cp -a "$SERVER_DIR/tools/." "$DEST/tools/"
fi

# 2) venv + deps (--system-site-packages: PyGObject/GdkPixbuf ke liye — app icons)
if [[ ! -x "$VENV/bin/python" ]]; then
  echo "==> venv bana raha hoon ($VENV)"
  python3 -m venv --system-site-packages "$VENV"
fi
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet -r "$DEST/server/requirements.txt"

# 2b) wtype — Unicode typing bina clipboard ke (wl-copy/wl-paste hata diye gaye).
#     Fedora RPM ko user-local ~/.local/bin me extract karte hain (sudo ki zaroorat nahi).
if ! command -v wtype >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/wtype" ]; then
  echo "==> wtype missing — Unicode typing ke liye install kar raha hoon"
  if command -v dnf >/dev/null 2>&1 && command -v rpm2cpio >/dev/null 2>&1 && command -v cpio >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    if (cd "$tmp" && dnf download --quiet wtype </dev/null >/dev/null 2>&1 \
        && rpm2cpio wtype-*.rpm | cpio -idm --quiet 2>/dev/null); then
      install -m 755 "$tmp/usr/bin/wtype" "$HOME/.local/bin/wtype"
      echo "    installed: $HOME/.local/bin/wtype"
    else
      echo "    WARN: wtype install fail — Unicode typing off rahegi."
      echo "          Manually: sudo dnf install wtype"
    fi
    rm -rf "$tmp"
  else
    echo "    WARN: wtype manually install karo: sudo dnf install wtype"
  fi
else
  echo "    wtype already available"
fi

# 3) icon + wrapper + desktop launcher (Linux se click karke control)
"$VENV/bin/python" "$DEST/tools/make_icon.py" "$DEST/mousify_icon.png"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" \
         "$HOME/.local/share/icons/hicolor/256x256/apps"
cp "$DEST/mousify_icon.png" "$HOME/.local/share/icons/hicolor/256x256/apps/mousify.png"

cat > "$HOME/.local/bin/mousify" <<EOF
#!/usr/bin/env bash
cd "$DEST/server" || exit 1
exec "$VENV/bin/python" -m mousify_server.manager --port ${MOUSIFY_PORT:-9898} "\$@"
EOF
chmod +x "$HOME/.local/bin/mousify"

cat > "$HOME/.local/share/applications/mousify.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Mousify
Comment=Phone → PC remote server (touchpad + typing)
Exec=$HOME/.local/bin/mousify
Icon=mousify
StartupWMClass=mousify
Terminal=false
Categories=Utility;Network;
StartupNotify=false
Actions=start;stop;qr;pair;

[Desktop Action start]
Name=Start server
Exec=$HOME/.local/bin/mousify --start

[Desktop Action stop]
Name=Stop server
Exec=$HOME/.local/bin/mousify --stop

[Desktop Action qr]
Name=Show QR code
Exec=$HOME/.local/bin/mousify --qr

[Desktop Action pair]
Name=Pairing code (6-digit)
Exec=sh -c '"$VENV/bin/python" -m mousify_server pair | tee /tmp/mousify-pair.txt > /dev/null; notify-send -i mousify "Mousify pairing code" "\$(head -3 /tmp/mousify-pair.txt | tail -1)"'
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -qtf "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# 4) systemd --user service
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/mousify.service" <<EOF
[Unit]
Description=Mousify server (phone -> PC mouse/keyboard remote)
After=network.target

[Service]
WorkingDirectory=$DEST/server
ExecStart="$VENV/bin/python" -m mousify_server run
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now mousify.service
sleep 1
systemctl --user --no-pager --lines=5 status mousify.service || true

echo
echo "==> Installed. NEXT STEPS:"
echo
echo "    1) /dev/uinput permission — EASIEST: open the Mousify desktop app"
echo "       and click 'Fix input permissions' (asks your sudo password via"
echo "       the native Fedora dialog). Or manually:"
echo
echo "       sudo sh -c 'echo KERNEL==\"uinput\", MODE==\"0666\" > /etc/udev/rules.d/80-mousify-uinput.rules'"
echo "       sudo udevadm control --reload-rules && sudo udevadm trigger"
echo
echo "       (no re-login needed — after this run: systemctl --user restart mousify)"
echo
echo "    2) Pairing: ~/.local/bin/mousify --qr   (scan from the phone app)"
echo "       or: $VENV/bin/python -m mousify_server pair"
