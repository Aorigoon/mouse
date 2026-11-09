"""Mousify desktop manager — server on/off, QR, input-permission fix.

Desktop icon se khulta hai. "Fix permissions" pkexec (polkit) ke zariye
Fedora ka native sudo password dialog dikha kar udev rule lagata hai —
password hamare code ke paas aata hi nahi.

CLI fallback: --status / --qr / --start / --stop / --fix-permissions
"""

import argparse
import os
import subprocess
import sys
import threading
from pathlib import Path

from . import __version__, config, qr

SERVICE = "mousify.service"


def _service_active() -> bool:
    out = subprocess.run(
        ["systemctl", "--user", "is-active", SERVICE],
        capture_output=True, text=True,
    ).stdout.strip()
    return out == "active"


def _service_ctl(action: str) -> None:
    subprocess.run(["systemctl", "--user", action, SERVICE], check=False)


def _uinput_ok() -> bool:
    try:
        fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
        os.close(fd)
        return True
    except OSError:
        return False


def _fix_permissions() -> tuple[bool, str]:
    """pkexec se root script chalata hai — polkit native password dialog."""
    script = Path(__file__).resolve().parent.parent / "tools" / "setup-permissions.sh"
    if not script.exists():
        return False, f"script missing: {script}"
    try:
        proc = subprocess.run(
            ["pkexec", "bash", str(script)],
            capture_output=True, text=True, timeout=180,
        )
    except FileNotFoundError:
        return False, "pkexec not found (polkit required)"
    if proc.returncode == 0 and "PERMISSIONS_OK" in proc.stdout:
        return True, "permissions fixed"
    if proc.returncode in (126, 127):
        return False, "authentication dismissed"
    err = (proc.stderr or "").strip().splitlines()
    return False, err[-1] if err else f"exit code {proc.returncode}"


def run_cli(args: argparse.Namespace) -> int:
    if args.fix_permissions:
        ok, msg = _fix_permissions()
        print(("OK — " if ok else "FAILED — ") + msg)
        if ok:
            _service_ctl("restart")
            print("service restarted — input should work now")
        return 0 if ok else 1
    if args.status:
        state = "running" if _service_active() else "stopped"
        print(f"Mousify service: {state}")
        print(f"Input (uinput)  : {'ready' if _uinput_ok() else 'BLOCKED — run --fix-permissions'}")
        print(f"Version         : {__version__}")
        return 0
    if args.qr:
        qr.show(qr.connect_uri(port=args.port))
        return 0
    if args.start:
        _service_ctl("start")
        print("started")
        return 0
    if args.stop:
        _service_ctl("stop")
        print("stopped")
        return 0
    return 1


def run_gui(port: int) -> None:
    """Tkinter manager window."""
    import tkinter as tk

    try:
        import qrcode
        from PIL import ImageTk
        HAS_QR = True
    except ImportError:
        HAS_QR = False

    # className → WM_CLASS="mousify" → taskbar/dock me Mousify icon (.desktop se)
    root = tk.Tk(className="mousify")
    root.title("Mousify Server")
    root.configure(bg="black")
    root.geometry("380x560")
    root.resizable(False, False)

    # window icon
    for icon_path in (
        Path.home() / ".local/share/mousify/mousify_icon.png",
        Path(__file__).resolve().parent.parent.parent / "mousify_icon.png",
    ):
        if icon_path.is_file():
            try:
                icon_img = tk.PhotoImage(file=str(icon_path))
                root.iconphoto(True, icon_img)
                root._mousify_icon = icon_img  # GC se bachao
                break
            except Exception:
                pass

    status_var = tk.StringVar(value="…")
    dot_var = tk.StringVar(value="○")
    input_var = tk.StringVar(value="…")

    def refresh_status():
        active = _service_active()
        status_var.set("Server running" if active else "Server stopped")
        dot_var.set("●" if active else "○")
        dot_label.configure(fg="white" if active else "#555555")
        start_btn.configure(state="disabled" if active else "normal")
        stop_btn.configure(state="normal" if active else "disabled")

        if _uinput_ok():
            input_var.set("Input: ready ✓")
            input_label.configure(fg="white")
            fix_btn.configure(state="disabled", text="Fix input permissions (admin)")
        else:
            input_var.set("Input: BLOCKED — cursor/keys won't work")
            input_label.configure(fg="#AAAAAA")
            fix_btn.configure(state="normal", text="Fix input permissions (admin password)")

    def refresh_now():
        refresh_status()

    tk.Label(
        root, text="MOUSIFY", fg="white", bg="black",
        font=("Sans", 16, "bold"),
    ).pack(pady=(18, 2))
    tk.Label(
        root, text=f"v{__version__}", fg="#666666", bg="black", font=("Sans", 9),
    ).pack()

    dot_label = tk.Label(root, textvariable=dot_var, fg="white", bg="black", font=("Sans", 20))
    dot_label.pack(pady=(10, 0))
    tk.Label(
        root, textvariable=status_var, fg="white", bg="black", font=("Sans", 12),
    ).pack(pady=(0, 8))

    def mk_btn(text, cmd, state="normal", bold=False):
        return tk.Button(
            root, text=text, command=cmd, state=state,
            bg="#161616", fg="white", activebackground="#2A2A2A",
            activeforeground="white", relief="flat", width=30, pady=7,
            font=("Sans", 11, "bold" if bold else "normal"), cursor="hand2",
        )

    start_btn = mk_btn("▶  Server start", lambda: (_service_ctl("start"), refresh_now()))
    stop_btn = mk_btn("■  Server stop", lambda: (_service_ctl("stop"), refresh_now()))
    start_btn.pack(pady=3)
    stop_btn.pack(pady=3)

    input_label = tk.Label(
        root, textvariable=input_var, fg="white", bg="black", font=("Sans", 10),
    )
    input_label.pack(pady=(14, 4))

    def show_pair_code():
        from . import config as cfg

        code = cfg.new_pair_code()
        win = tk.Toplevel(root)
        win.title("Pairing code")
        win.configure(bg="black")
        tk.Label(
            win, text=code, fg="white", bg="black",
            font=("Monospace", 34, "bold"),
        ).pack(padx=30, pady=(24, 6))
        tk.Label(
            win, text='Phone app → Settings → "Pair with 6-digit code"',
            fg="#888888", bg="black", font=("Sans", 10),
        ).pack(pady=(0, 4))
        tk.Label(
            win, text="Valid for 5 minutes", fg="#555555", bg="black",
            font=("Sans", 9),
        ).pack(pady=(0, 18))
        win.eval("tk::PlaceWindow . center")

    def mk_pair_btn():
        return tk.Button(
            root, text="Show pairing code (6-digit)", command=show_pair_code,
            bg="#161616", fg="white", activebackground="#2A2A2A",
            activeforeground="white", relief="flat", width=30, pady=7,
            font=("Sans", 11), cursor="hand2",
        )

    pair_btn = mk_pair_btn()
    pair_btn.pack(pady=3)

    def do_fix():
        fix_btn.configure(state="disabled", text="Waiting for admin password…")
        result: dict = {}

        def worker():
            result["r"] = _fix_permissions()
            root.after(0, on_done)

        def on_done():
            ok, msg = result.get("r", (False, "no result"))
            if ok:
                _service_ctl("restart")
            refresh_now()
            from tkinter import messagebox

            if ok:
                messagebox.showinfo(
                    "Mousify", "Permissions fixed — server restarted.\nInput should work now.",
                )
            else:
                messagebox.showwarning("Mousify", f"Couldn't fix permissions:\n{msg}")

        threading.Thread(target=worker, daemon=True).start()

    fix_btn = mk_btn("Fix input permissions (admin password)", do_fix)
    fix_btn.pack(pady=3)

    tk.Label(
        root, text="────   PHONE CONNECT   ────", fg="#555555", bg="black",
        font=("Sans", 9),
    ).pack(pady=(14, 6))

    qr_photo = {"img": None}

    def show_qr():
        uri = qr.connect_uri(port=port)
        if HAS_QR:
            win = tk.Toplevel(root)
            win.title("QR — scan with the phone")
            win.configure(bg="black")
            img = qrcode.make(uri, box_size=7, border=2)
            qr_photo["img"] = ImageTk.PhotoImage(img)
            tk.Label(win, image=qr_photo["img"], bg="black").pack(padx=20, pady=(20, 6))
            tk.Label(
                win, text='Phone app → Settings → "Scan QR"',
                fg="white", bg="black", font=("Sans", 11),
            ).pack(pady=(0, 4))
            tk.Label(
                win, text=uri, fg="#888888", bg="black", font=("Monospace", 7),
                wraplength=300,
            ).pack(pady=(0, 14))
            win.eval("tk::PlaceWindow . center")
        else:
            path = qr.make_png(uri, "/tmp/mousify-qr.png")
            subprocess.run(["xdg-open", path], check=False)

    tk.Button(
        root, text="Show QR code", command=show_qr,
        bg="white", fg="black", activebackground="#DDDDDD",
        activeforeground="black", relief="flat", width=30, pady=7,
        font=("Sans", 11, "bold"), cursor="hand2",
    ).pack(pady=6)

    refresh_status()
    root.eval("tk::PlaceWindow . center")
    root.mainloop()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="mousify-manager")
    parser.add_argument("--port", type=int, default=config.DEFAULT_PORT)
    parser.add_argument("--qr", action="store_true", help="show QR window only")
    parser.add_argument("--status", action="store_true", help="print service status")
    parser.add_argument("--start", action="store_true", help="start service")
    parser.add_argument("--stop", action="store_true", help="stop service")
    parser.add_argument(
        "--fix-permissions", action="store_true",
        help="fix /dev/uinput permissions via pkexec (native sudo dialog)",
    )
    args = parser.parse_args(argv)

    if args.fix_permissions or args.qr or args.status or args.start or args.stop:
        return run_cli(args)
    try:
        run_gui(port=args.port)
    except Exception as e:
        print(f"GUI failed ({e}) — use CLI: --status / --qr / --fix-permissions", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
