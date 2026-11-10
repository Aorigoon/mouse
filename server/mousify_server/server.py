"""WebSocket server — phone se JSON events leta hai aur injector tak pahunchata hai.

Saath me ek chhota HTTP server (port+1) icons serve karta hai:
GET /icon/<app-id>.png  →  app ka 128px PNG
"""

import asyncio
import base64
import json
import logging
import platform
import secrets
import socket
import time
from pathlib import Path

from . import commands, config, keymap
from .apps import AppRegistry
from .injector import Injector, MockInjector

log = logging.getLogger("mousify.server")

HELLO_TIMEOUT = 5.0
MAX_TEXT_LEN = 200_000

# /etc/os-release ke ID se display naam — phone par chip me dikhta hai.
_LINUX_DISTROS = {
    "fedora": "Fedora",
    "ubuntu": "Ubuntu",
    "debian": "Debian",
    "arch": "Arch Linux",
    "pop": "Pop!_OS",
    "manjaro": "Manjaro",
    "opensuse": "openSUSE",
    "linuxmint": "Linux Mint",
    "elementary": "elementary OS",
    "zorin": "Zorin OS",
    "kali": "Kali Linux",
    "rhel": "RHEL",
    "centos": "CentOS",
    "almalinux": "AlmaLinux",
    "rocky": "Rocky Linux",
}


def detect_os() -> str:
    """PC ka OS naam — Windows / macOS / Fedora / Ubuntu / ..."""
    system = platform.system()
    if system == "Windows":
        return "Windows"
    if system == "Darwin":
        return "macOS"
    if system == "Linux":
        try:
            fields = {}
            for line in Path("/etc/os-release").read_text().splitlines():
                if "=" in line:
                    k, _, v = line.partition("=")
                    fields[k.strip()] = v.strip().strip('"')
            distro_id = fields.get("ID", "").lower()
            if distro_id in _LINUX_DISTROS:
                return _LINUX_DISTROS[distro_id]
            name = fields.get("NAME", "")
            # "Fedora Linux" -> Fedora, "Debian GNU/Linux" -> Debian
            for suffix in (" GNU/Linux", " Linux"):
                if name.endswith(suffix):
                    name = name[: -len(suffix)]
            if name:
                return name
        except OSError:
            pass
        return "Linux"
    return system or "Unknown"


class MousifyServer:
    def __init__(self, injector: Injector | MockInjector, port: int = config.DEFAULT_PORT) -> None:
        self.injector = injector
        self.port = port
        self.icon_port = port + 1
        self.host_name = socket.gethostname()
        self.os_name = detect_os()
        self.apps = AppRegistry()
        self.clients: set = set()

    # --- handshake / auth ---------------------------------------------------
    async def _handshake(self, ws) -> bool:
        """Pehla 'hello' message handle karta hai. True = connection qabool."""
        try:
            raw = await asyncio.wait_for(ws.recv(), timeout=HELLO_TIMEOUT)
            msg = json.loads(raw)
        except (asyncio.TimeoutError, json.JSONDecodeError):
            return False
        if msg.get("t") != "hello":
            return False

        token = config.load_token()
        if token and msg.get("token") == token:
            await ws.send(json.dumps({"t": "hello-ok", "host": self.host_name, "os": self.os_name}))
            return True

        if msg.get("pair_code") and config.check_pair_code(msg["pair_code"]):
            # Har pairing par naya token (purane clients disconnect ho jayenge)
            token = secrets.token_hex(16)
            config.save_token(token)
            await ws.send(json.dumps({"t": "paired", "token": token, "host": self.host_name, "os": self.os_name}))
            return True

        await ws.send(json.dumps({"t": "pair-required"}))
        return False

    # --- event dispatch -----------------------------------------------------
    async def _dispatch(self, ws, msg: dict) -> None:
        t = msg.get("t")

        if t == "ping":
            await ws.send(json.dumps({"t": "pong", "host": self.host_name}))

        elif t == "move":
            self.injector.move(msg.get("dx", 0) or 0, msg.get("dy", 0) or 0)

        elif t == "scroll":
            self.injector.scroll(msg.get("dy", 0) or 0, msg.get("dx", 0) or 0)

        elif t == "button":
            self.injector.button(msg.get("b", "left"), msg.get("a", "click"))

        elif t == "key":
            k = str(msg.get("k", "")).lower()
            code = keymap.SPECIAL_KEYS.get(k)
            if code is None and len(k) == 1:
                mapping = keymap.CHAR_TO_KEY.get(k)
                if mapping:
                    code = mapping[0]
            if code is None:
                await ws.send(json.dumps({"t": "error", "msg": f"unknown key: {msg.get('k')}"}))
                return
            count = max(1, min(int(msg.get("count", 1) or 1), 1000))
            for _ in range(count):
                self.injector.tap_key(
                    code,
                    ctrl=bool(msg.get("ctrl")),
                    shift=bool(msg.get("shift")),
                    alt=bool(msg.get("alt")),
                )

        elif t == "text":
            text = str(msg.get("s", ""))[:MAX_TEXT_LEN]
            if not text:
                return
            # Paste at once into the focused field (no live typing).
            if isinstance(self.injector, MockInjector):
                log.info("mock paste %r", text[:60])
            else:
                await asyncio.to_thread(self._real_paste, text)

        elif t == "paste":
            # Backwards compatibility for old app builds.
            text = str(msg.get("s", ""))[:MAX_TEXT_LEN]
            if not text:
                return
            if isinstance(self.injector, MockInjector):
                log.info("mock paste %r", text[:60])
            else:
                await asyncio.to_thread(self._real_paste, text)

        elif t == "apps-list":
            entries = await asyncio.to_thread(self.apps.scan)
            await ws.send(json.dumps({
                "t": "apps",
                "apps": [
                    {"id": a.id, "name": a.name}
                    for a in entries
                ],
            }))

        elif t == "launch":
            app_id = str(msg.get("id", ""))[:200]
            mode = await asyncio.to_thread(self.apps.launch, app_id)
            if mode == "not-found":
                await ws.send(json.dumps({"t": "error", "msg": f"app not found: {app_id}"}))
            else:
                await ws.send(json.dumps({"t": "launched", "mode": mode}))

        elif t == "check-typing":
            from . import focus

            res = await asyncio.to_thread(focus.is_typing_target)
            await ws.send(json.dumps({
                "t": "typing-target",
                "ok": res is True,
                "supported": res is not None,
            }))

        elif t == "media":
            action = str(msg.get("action", ""))
            await ws.send(json.dumps({
                "t": "media-ok", "action": action,
                "found": commands.media_action(action),
            }))

        elif t == "volume":
            commands.set_volume(int(msg.get("value", 0) or 0))

        elif t == "volume-get":
            v = await asyncio.to_thread(commands.get_volume)
            await ws.send(json.dumps({"t": "volume", "value": v}))

        elif t == "clip-get" or t == "clip-set":
            # Clipboard feature removed: wl-copy/wl-paste broke the GNOME dock.
            await ws.send(json.dumps({
                "t": "error",
                "msg": "clipboard feature removed (use composer typing)",
            }))

        elif t == "screenshot":
            data, reason = await asyncio.to_thread(commands.screenshot)
            if data:
                await ws.send(json.dumps({
                    "t": "shot", "data": base64.b64encode(data).decode(),
                }))
            else:
                await ws.send(json.dumps({"t": "shot-fail", "reason": reason}))

        elif t == "windows-list":
            from . import focus

            wins = await asyncio.to_thread(focus.list_windows)
            await ws.send(json.dumps({"t": "windows", "windows": wins}))

        elif t == "focus-window":
            from . import focus

            ok = await asyncio.to_thread(
                focus.focus_window_by,
                str(msg.get("app", ""))[:200],
                str(msg.get("title", ""))[:300],
            )
            await ws.send(json.dumps({"t": "focused", "ok": ok}))

        elif t == "terminal-peek":
            from . import focus

            res = await asyncio.to_thread(focus.peek_terminal)
            await ws.send(json.dumps({"t": "terminal-text", **res}))

        else:
            await ws.send(json.dumps({"t": "error", "msg": f"unknown type: {t}"}))

    def _real_paste(self, text: str) -> None:
        """Text ko clipboard me daal kar focused field me Ctrl+V se paste karo."""
        if commands.set_clipboard(text):
            time.sleep(0.08)  # clipboard settle hone do
            self.injector.ctrl_v()
        else:
            # Clipboard fail ho to seedha type kar do (fallback).
            self.injector.type_text(text)

    # --- connection loop ----------------------------------------------------
    async def handler(self, ws) -> None:
        peer = getattr(ws, "remote_address", None)
        if not await self._handshake(ws):
            log.info("client reject hua: %s", peer)
            return
        log.info("client connected: %s", peer)
        self.clients.add(ws)
        try:
            async for raw in ws:
                try:
                    msg = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                try:
                    await self._dispatch(ws, msg)
                except Exception:
                    log.exception("event fail: %r", msg)
                    try:
                        await ws.send(json.dumps({"t": "error", "msg": "event failed"}))
                    except Exception:
                        pass
        finally:
            self.clients.discard(ws)
            log.info("client gone: %s", peer)

    async def run(self) -> None:
        from websockets.asyncio.server import serve

        # startup par apps scan (background, non-blocking)
        asyncio.create_task(asyncio.to_thread(self.apps.scan))
        icon_task = asyncio.create_task(self._icon_http_server())
        async with serve(self.handler, "0.0.0.0", self.port, max_size=2 ** 22):
            log.info(
                "listening on 0.0.0.0:%s (icons on :%s)", self.port, self.icon_port
            )
            icon_task.cancel()
            await asyncio.Future()  # hamesha ke liye

    async def _icon_http_server(self) -> None:
        """Chhota HTTP server — /icon/<app-id> par app ka PNG deta hai."""

        async def handle(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
            try:
                request_line = await asyncio.wait_for(reader.readline(), timeout=5)
                parts = request_line.decode("utf-8", "ignore").split()
                if len(parts) >= 2 and parts[0] == "GET" and parts[1].startswith("/icon/"):
                    app_id = parts[1][len("/icon/"):].strip()
                    png = await asyncio.to_thread(self.apps.icon_png, app_id)
                    if png:
                        data = Path(png).read_bytes()
                        header = (
                            "HTTP/1.1 200 OK\r\n"
                            "Content-Type: image/png\r\n"
                            f"Content-Length: {len(data)}\r\n"
                            "Cache-Control: max-age=86400\r\n"
                            "Connection: close\r\n\r\n"
                        )
                        writer.write(header.encode() + data)
                        await writer.drain()
                        return
                writer.write(
                    b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n"
                    b"Connection: close\r\n\r\n"
                )
                await writer.drain()
            except Exception:
                pass
            finally:
                try:
                    writer.close()
                except Exception:
                    pass

        server = await asyncio.start_server(handle, "0.0.0.0", self.icon_port)
        log.info("icon http server on 0.0.0.0:%s", self.icon_port)
        async with server:
            await server.serve_forever()

