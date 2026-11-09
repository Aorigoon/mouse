"""QR code — phone ko scan karke seedha connect karane ke liye.

Payload: mousify://connect?host=<ip>&port=<port>&token=<token>
Token na ho to khud bana leta hai (QR scan = pairing, 6-digit ki zarurat nahi).
"""

import logging
import subprocess

from . import config, discovery

log = logging.getLogger("mousify.qr")


def connect_uri(port: int, token: str | None = None) -> str:
    """Phone app jo URI scan karega."""
    if token is None:
        token = config.load_token()
        if token is None:
            token = config.new_token()
    host = discovery.lan_ip()
    return f"mousify://connect?host={host}&port={port}&token={token}"


def make_png(uri: str, path: str, box_size: int = 10) -> str:
    """QR PNG generate karke path par save karta hai. Return: path."""
    import qrcode

    img = qrcode.make(uri, box_size=box_size, border=2)
    img.save(path)
    return path


def show_window(uri: str) -> None:
    """Tkinter window me QR dikhata hai (PIL ImageTk ke saath)."""
    import io

    import qrcode
    from PIL import ImageTk
    import tkinter as tk

    img = qrcode.make(uri, box_size=8, border=2)

    root = tk.Tk()
    root.title("Mousify — QR se connect karo")
    root.resizable(False, False)
    root.configure(bg="black")

    photo = ImageTk.PhotoImage(img)
    panel = tk.Label(root, image=photo, bg="black")
    panel.pack(padx=24, pady=(24, 8))

    tk.Label(
        root, text="Phone app → Settings → 'QR Scan' se ye scan karo",
        fg="white", bg="black", font=("Sans", 11),
    ).pack(pady=(0, 4))
    tk.Label(
        root, text=uri, fg="#888888", bg="black", font=("Monospace", 8),
        wraplength=340,
    ).pack(pady=(0, 16))

    root.eval("tk::PlaceWindow . center")
    root.mainloop()


def show(uri: str) -> None:
    """QR window kholo; tkinter na chale to PNG save karke default viewer me."""
    try:
        show_window(uri)
    except Exception:
        log.exception("tkinter QR window fail — PNG viewer fallback")
        path = make_png(uri, "/tmp/mousify-qr.png")
        subprocess.run(["xdg-open", path], check=False)
