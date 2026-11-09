"""Focused UI element typing-field hai? — AT-SPI (pyatspi) se detection.

GNOME Wayland par at-spi2 chal raha hota hai; active frame ka focused widget
role check karte hain (entry/text/terminal/...).
Return: True/False (pata chala) ya None (detect nahi kar saka — phone phir
purane behavior par fall back karega: composer khul jayega).

Fast path: agar active frame ka role hi typing-role hai (terminal etc.) to
deep search ki zarurat nahi. Deep search time-budget + node-cap ke saath.
"""

import logging
import time

log = logging.getLogger("mousify.focus")

_TYPING_ROLES = {
    "text",
    "entry",
    "password text",
    "document text",
    "document spreadsheet",
    "document email",
    "terminal",
    "spin box",
}

_TIME_BUDGET = 0.6  # seconds
_MAX_NODES = 600
_MAX_DEPTH = 10


def is_typing_target() -> bool | None:
    try:
        import pyatspi
    except ImportError:
        log.debug("pyatspi nahi mila — typing-target detection unsupported")
        return None

    deadline = time.monotonic() + _TIME_BUDGET
    try:
        desktop = pyatspi.Registry.getDesktop(0)
    except Exception:
        return None

    try:
        for app in desktop:
            if time.monotonic() > deadline:
                return None
            try:
                for frame in app:
                    result = _scan_frame(pyatspi, frame, deadline)
                    if result is not None:
                        return result
            except Exception:
                continue
    except Exception:
        return None
    return None


def peek_terminal(max_chars: int = 4000) -> dict:
    """Active terminal ka visible text (AT-SPI Text interface) — preview ke liye."""
    try:
        import pyatspi
    except ImportError:
        return {"ok": False, "text": "", "reason": "unsupported"}
    deadline = time.monotonic() + 1.0
    try:
        desktop = pyatspi.Registry.getDesktop(0)
        for app in desktop:
            try:
                for frame in app:
                    if time.monotonic() > deadline:
                        break
                    try:
                        if not frame.getState().contains(pyatspi.STATE_ACTIVE):
                            continue
                    except Exception:
                        continue
                    # active frame ke andar terminal-role node dhoondo
                    stack = [frame]
                    visited = 0
                    while stack and visited < 400:
                        node = stack.pop(0)
                        visited += 1
                        try:
                            role = node.getRoleName().strip().lower()
                            if role == "terminal":
                                txt = node.queryText()
                                count = txt.characterCount
                                if count > 0:
                                    start = max(0, count - max_chars)
                                    return {
                                        "ok": True,
                                        "text": txt.getText(start, count),
                                    }
                        except Exception:
                            pass
                        try:
                            for child in node:
                                stack.append(child)
                        except Exception:
                            pass
            except Exception:
                continue
    except Exception:
        pass
    return {"ok": False, "text": "", "reason": "no active terminal found"}


def list_windows(max_items: int = 40) -> list[dict]:
    """Khuli windows (app + title) — app switcher ke liye."""
    out: list[dict] = []
    try:
        import pyatspi
    except ImportError:
        return out
    try:
        desktop = pyatspi.Registry.getDesktop(0)
        for app in desktop:
            try:
                app_name = (app.name or "").strip()
                if not app_name or app_name in (
                    "gnome-shell", "xwaylandvideobridge",
                ):
                    continue
                for frame in app:
                    try:
                        title = (frame.name or "").strip()
                        if not title:
                            continue
                        out.append({"app": app_name, "title": title})
                        if len(out) >= max_items:
                            return out
                    except Exception:
                        continue
            except Exception:
                continue
    except Exception:
        pass
    return out


def focus_window_by(app_name: str, title: str) -> bool:
    """Match karke window par grabFocus (switch)."""
    try:
        import pyatspi
    except ImportError:
        return False
    a = app_name.strip().lower()
    t = title.strip().lower()
    try:
        desktop = pyatspi.Registry.getDesktop(0)
        for app in desktop:
            try:
                running = (app.name or "").strip().lower()
                if running != a:
                    continue
                for frame in app:
                    try:
                        if (frame.name or "").strip().lower() != t:
                            continue
                        frame.queryComponent().grabFocus()
                        return True
                    except Exception:
                        continue
            except Exception:
                continue
    except Exception:
        pass
    return False


def _scan_frame(pyatspi, frame, deadline: float) -> bool | None:
    """Active frame ke andar focused object dhoondo (BFS, budget ke saath)."""
    try:
        state = frame.getState()
        if not state.contains(pyatspi.STATE_ACTIVE):
            return None
    except Exception:
        return None

    # fast path — frame ka role khud typing-role hai (terminal etc.)
    try:
        role = frame.getRoleName().strip().lower()
        if role in _TYPING_ROLES:
            return True
    except Exception:
        pass

    visited = 0
    stack = [(frame, 0)]
    while stack and visited < _MAX_NODES:
        if time.monotonic() > deadline:
            return None
        node, depth = stack.pop(0)
        visited += 1
        try:
            if node.getState().contains(pyatspi.STATE_FOCUSED):
                role = node.getRoleName().strip().lower()
                log.debug("focused role: %s", role)
                return role in _TYPING_ROLES
        except Exception:
            pass
        if depth < _MAX_DEPTH:
            try:
                for child in node:
                    stack.append((child, depth + 1))
            except Exception:
                pass
    return None
