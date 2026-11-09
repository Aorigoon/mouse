"""Dock ke quick commands: media (MPRIS), volume (pactl), Unicode typing, screenshot."""

import logging
import os
import shutil
import subprocess
import time

log = logging.getLogger("mousify.commands")


def _run(cmd: list[str], timeout: float = 8) -> str:
    try:
        out = subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout
        ).stdout
        return out.strip()
    except Exception:
        return ""


# ---- media (MPRIS) -----------------------------------------------------------
def _media_players() -> list[str]:
    out = _run(["busctl", "--user", "list", "--no-legend"])
    return [
        line.split()[0]
        for line in out.splitlines()
        if "org.mpris.MediaPlayer2" in line
    ]


def media_action(action: str) -> bool:
    """playpause / next / previous — pehle chalte hue player par."""
    method = {
        "playpause": "PlayPause",
        "next": "Next",
        "prev": "Previous",
    }.get(action)
    if not method:
        return False
    for player in _media_players():
        r = _run([
            "busctl", "--user", "call", player, "/org/mpris/MediaPlayer2",
            "org.mpris.MediaPlayer2.Player", method,
        ], timeout=5)
        log.debug("media %s on %s", action, player)
        return True
    return False


# ---- volume ------------------------------------------------------------------
def get_volume() -> int | None:
    out = _run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"])
    # "Volume: front-left: 65536 / 100% / ..."
    try:
        for part in out.replace(",", " ").split():
            if part.endswith("%"):
                return int(part[:-1])
    except Exception:
        pass
    return None


def set_volume(value: int) -> None:
    value = max(0, min(100, int(value)))
    _run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{value}%"])


# ---- Wayland env + clipboard (paste) -----------------------------------------
def _wayland_env() -> dict:
    env = os.environ.copy()
    if not env.get("XDG_RUNTIME_DIR"):
        env["XDG_RUNTIME_DIR"] = f"/run/user/{os.getuid()}"
    if not env.get("WAYLAND_DISPLAY"):
        runtime = env["XDG_RUNTIME_DIR"]
        for name in ("wayland-0", "wayland-1", "wayland-2"):
            if os.path.exists(os.path.join(runtime, name)):
                env["WAYLAND_DISPLAY"] = name
                break
        else:
            env["WAYLAND_DISPLAY"] = "wayland-0"
    return env


def set_clipboard(text: str) -> bool:
    """Wayland clipboard me text rakho (wl-copy)."""
    try:
        subprocess.run(
            ["wl-copy"],
            input=text.encode("utf-8"),
            timeout=5,
            check=False,
            env=_wayland_env(),
        )
        return True
    except Exception:
        log.exception("set_clipboard fail")
        return False


# ---- Unicode typing (fallback, no clipboard) ---------------------------------
def _wtype_path() -> str | None:
    path = shutil.which("wtype")
    if path:
        return path
    local = os.path.expanduser("~/.local/bin/wtype")
    return local if os.access(local, os.X_OK) else None


def type_unicode(text: str) -> bool:
    """Type arbitrary Unicode via wtype (Wayland virtual keyboard)."""
    wtype = _wtype_path()
    if not wtype:
        return False

    env = _wayland_env()
    env.setdefault("XDG_SESSION_TYPE", "wayland")

    try:
        subprocess.run(
            [wtype, "-"],
            input=text.encode("utf-8"),
            timeout=60,
            check=False,
            env=env,
        )
        return True
    except Exception:
        log.exception("type_unicode fail")
        return False


# ---- screenshot (portal — PC par Capture dialog aata hai) ----------------------
def screenshot() -> tuple[bytes | None, str]:
    try:
        import gi

        gi.require_version("Gio", "2.0")
        from gi.repository import Gio, GLib
    except ImportError:
        return None, "gio unavailable"

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        token = f"mousify{int(time.time())}"
        sender = bus.get_unique_name().lstrip(":").replace(".", "_")
        request_path = (
            f"/org/freedesktop/portal/desktop/request/{sender}/{token}"
        )
        result: dict = {}
        ctx = GLib.main_context_default()

        def on_response(_conn, _sender, path, _iface, _signal, params):
            if path != request_path:
                return
            result["resp"] = params[0]
            try:
                uri_v = params[1].get("uri")
                result["uri"] = (
                    uri_v.unpack() if hasattr(uri_v, "unpack") else uri_v
                )
            except Exception:
                result["uri"] = None
            ctx.quit()

        sub = bus.signal_subscribe(
            None, "org.freedesktop.portal.Request", "Response",
            request_path, None, Gio.DBusSignalFlags.NONE, on_response,
        )
        options = GLib.Variant(
            "(sa{sv})", ("", {"handle_token": GLib.Variant("s", token)})
        )
        bus.call_sync(
            "org.freedesktop.portal.Desktop",
            "/org/freedesktop/portal/desktop",
            "org.freedesktop.portal.Screenshot",
            "Screenshot",
            options, None, Gio.DBusCallFlags.NONE, -1, None,
        )

        deadline = time.monotonic() + 45
        while time.monotonic() < deadline and "uri" not in result:
            ctx.iteration(True)
        bus.signal_unsubscribe(sub)

        resp = result.get("resp")
        uri = result.get("uri")
        if resp != 0 or not uri:
            return None, "cancelled on PC" if resp == 1 else "no response"
        path = uri.replace("file://", "") if uri.startswith("file://") else uri
        with open(path, "rb") as f:
            return f.read(), "ok"
    except Exception as e:
        log.exception("screenshot fail")
        return None, str(e)
