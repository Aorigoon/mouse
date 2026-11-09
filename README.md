# Mousify

Phone ko Linux PC ka **touchpad + keyboard** banao — Wi-Fi/LAN par. Khaas karke
voice-to-text (Wispr Flow / Gboard mic) se likhe hue prompts **seedha** coding
agent CLI me bhejo. WhatsApp ka copy-paste loop khatam.

```
Phone (Flutter app)  ←── WebSocket (LAN) ──→  Linux PC (Python server → uinput)
```

- **`app/`** — Flutter Android app (touchpad, composer, settings). Pure black & white.
- **`server/`** — Python server: WebSocket + mDNS + kernel-level uinput injection.

Wayland (GNOME) par bhi chalta hai — input ek asli kernel virtual device se aata
hai (xdotool jaise X11 tools yahan kaam nahi karte).

---

## PC setup (one time)

### 1) Server install

```bash
cd server
bash install.sh
```

Ye `~/.local/share/mousify/` me venv + code install karta hai aur systemd
user service enable karta hai. (Workspace agar NTFS/external mount par ho to bhi
theek — install native filesystem par hota hai.)

### 2) /dev/uinput permission (sudo chahiye)

```bash
sudo sh -c 'echo KERNEL=="uinput", MODE=="0660", GROUP=="input" > /etc/udev/rules.d/80-mousify-uinput.rules'
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG input $USER
```

**Phir logout/reboot karo** — group membership naye session me lagti hai.

> Note: ye step ke bina server `dry-run` mode me chalega (sirf logging, input nahi).

### 3) Connect — QR se (recommended)

Desktop par **Mousify** icon kholo (Activities me dikh jayega) → **"QR Code dikhao"**
→ phone app me **Settings → QR se connect karo** → scan. Bas — token khud save ho jata hai.

Ya terminal se:
```bash
~/.local/bin/mousify --qr     # QR window
~/.local/bin/mousify --status # service status
```

### 4) Pairing (6-digit code — QR ka alternative)

```bash
~/.local/share/mousify/venv/bin/python -m mousify_server pair
```

6-digit code print hoga → phone app me Settings → "Pair naya server".

## Linux desktop app

`install.sh` ye sab install karta hai:

- **Desktop icon "Mousify"** (Activities/app grid me) — click karo → manager window:
  server Start/Stop buttons, QR code, status. Right-click par bhi actions milte hain.
- **`~/.local/bin/mousify`** CLI: `--start | --stop | --status | --qr`
- **systemd user service** — login par server **khud start** ho jata hai
  (PC restart ke baad kuch karne ki zarurat nahi):
  `systemctl --user status mousify`

## Phone app

```bash
cd app
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

1. Phone aur PC **same Wi-Fi** par hon.
2. App kholo → Settings → **QR se connect karo** (PC par QR kholo) — scan ke baad
   **connect hua ya nahi, dialog me saaf pata chalta hai**.
   Ya discovered server tap karo / manual IP.
3. Theme: **Light default** hai; Settings → Appearance me Dark bhi.
3. Home: touchpad se cursor, neeche bar se composer kholo — **mic se dictate karo,
   Send dabao** — text PC ke focused window me type ho jayega.

## Use

| Gesture | Action |
|---|---|
| 1 ungli drag | cursor move |
| 1 ungli tap | left click |
| 2 ungli tap | right click |
| 2 ungli drag up/down | scroll |
| long-press (350ms) | left button hold (drag) |
| 🔒 button | drag lock toggle |

Composer ka text **asli keystrokes** se type hota hai (uinput). ASCII (Roman
Urdu) seedha uinput se jata hai; Unicode (Urdu script, emoji) `wtype` se type
hota hai. **Clipboard (wl-copy/wl-paste) bilkul use nahi hota** — is liye GNOME
ke dock/taskbar par koi hidden window nahi aata aur screen blink nahi hoti.

> **Note (Nov 2026):** PC ↔ phone clipboard sync feature jaan bujh kar hata diya
> gaya hai. `wl-paste` ka 1.5s poll GNOME Shell me
> `meta_window_set_stack_position_no_sync` spam, dock freeze aur screen blink
> paida karta tha. Ab koi clipboard dependency nahi.

## Commands

```bash
VENV=~/.local/share/mousify/venv/bin/python
$VENV -m mousify_server run            # server chalao (foreground)
$VENV -m mousify_server run --dry-run  # bina uinput ke test
$VENV -m mousify_server pair           # pairing code
$VENV -m mousify_server status         # config/service status
$VENV -m mousify_server selftest       # keymap test
systemctl --user status mousify        # service status
```

Dev mode (workspace se seedha):
```bash
cd server && ~/.local/share/mousify/venv/bin/python -m mousify_server run
```

## Troubleshooting

- **Cursor nahi hilta**: `ls -l /dev/uinput` — agar `root root` ho to §2 ka udev
  step aur re-login missing hai. Server log me "DRY-RUN" dikh raha ho to wahi masla hai.
- **Server nahi dikhta (discovery)**: router multicast block kar sakta hai — manual
  IP daalo (`ip addr show | grep inet`).
- **Connect nahi hota**: firewall — `sudo firewall-cmd --add-port=9898/tcp --permanent && sudo firewall-cmd --reload`.
- **Unicode type nahi ho raha**: `wtype` missing hai — `sudo dnf install wtype`
  (installer khud bhi user-local install karne ki koshish karta hai).
- **Build issues (agar workspace NTFS mount par hai)**: `rsync -a app/ ~/mousify-app/` karke home se build karo.

## Architecture notes

- Protocol: JSON over WebSocket (port 9898) — `move/scroll/button/key/text/ping`.
  (`paste` sirf purani app builds ke liye alias hai; wo bhi clipboard use nahi karta,
  `wtype` se type karta hai.)
- Auth: QR me token hota hai (`mousify://connect?host=…&port=…&token=…`) ya 6-digit
  pairing → token (`~/.config/mousify/token`), har naye pairing par rotate.
- mDNS: `_mousify._tcp` (python-zeroconf advertise, app me bonsoir discovery).
- Injection: pure-Python uinput (`fcntl.ioctl`) — koi C extension dependency nahi
  (evdev ka Python 3.14 wheel nahi tha).
- Desktop: tkinter manager + `.desktop` launcher + qrcode[pil].
