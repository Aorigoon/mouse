"""uinput virtual device — kernel-level mouse/keyboard event injection.

GNOME Wayland par xdotool-type tools kaam nahi karte; uinput device kernel
me asli hardware jaisa dikhta hai is liye ye Wayland + XWayland dono me chalta hai.
"""

import logging
import threading
import time

from . import keymap
from .uinput import (
    BTN_EXTRA,
    BTN_LEFT,
    BTN_MIDDLE,
    BTN_RIGHT,
    BTN_SIDE,
    EV_KEY,
    EV_REL,
    KEY_LEFTALT,
    KEY_LEFTCTRL,
    KEY_LEFTSHIFT,
    KEY_V,
    REL_HWHEEL,
    REL_WHEEL,
    REL_X,
    REL_Y,
    UInputDevice,
)

log = logging.getLogger("mousify.injector")

_INT16_MAX = 32767


class Injector:
    """Asli uinput device. /dev/uinput par write permission chahiye (README dekho)."""

    def __init__(self, name: str = "Mousify Virtual Input") -> None:
        self._lock = threading.Lock()
        caps = keymap.capabilities()
        self.dev = UInputDevice(
            key_bits=caps[EV_KEY], rel_bits=caps[EV_REL], name=name
        )
        log.info("uinput device ready: %s", name)

    # --- mouse --------------------------------------------------------------
    def move(self, dx: int, dy: int) -> None:
        dx = max(-_INT16_MAX, min(_INT16_MAX, int(dx)))
        dy = max(-_INT16_MAX, min(_INT16_MAX, int(dy)))
        with self._lock:
            if dx:
                self.dev.write_event(EV_REL, REL_X, dx)
            if dy:
                self.dev.write_event(EV_REL, REL_Y, dy)
            self.dev.syn()

    def scroll(self, dy: int = 0, dx: int = 0) -> None:
        with self._lock:
            if dy:
                self.dev.write_event(EV_REL, REL_WHEEL, int(dy))
            if dx:
                self.dev.write_event(EV_REL, REL_HWHEEL, int(dx))
            self.dev.syn()

    def button(self, btn: str, action: str) -> None:
        code = {
            "left": BTN_LEFT,
            "right": BTN_RIGHT,
            "middle": BTN_MIDDLE,
            "side": BTN_SIDE,
            "extra": BTN_EXTRA,
        }.get(btn)
        if code is None:
            raise ValueError(f"unknown button: {btn}")
        with self._lock:
            if action == "click":
                self.dev.write_event(EV_KEY, code, 1)
                self.dev.syn()
                time.sleep(0.01)
                self.dev.write_event(EV_KEY, code, 0)
                self.dev.syn()
            elif action in ("down", "up"):
                self.dev.write_event(EV_KEY, code, 1 if action == "down" else 0)
                self.dev.syn()
            else:
                raise ValueError(f"unknown action: {action}")

    # --- keyboard -----------------------------------------------------------
    def tap_key(
        self,
        code: int,
        shift: bool = False,
        ctrl: bool = False,
        alt: bool = False,
    ) -> None:
        mods = []
        if ctrl:
            mods.append(KEY_LEFTCTRL)
        if shift:
            mods.append(KEY_LEFTSHIFT)
        if alt:
            mods.append(KEY_LEFTALT)
        with self._lock:
            for m in mods:
                self.dev.write_event(EV_KEY, m, 1)
            self.dev.write_event(EV_KEY, code, 1)
            self.dev.syn()
            self.dev.write_event(EV_KEY, code, 0)
            for m in reversed(mods):
                self.dev.write_event(EV_KEY, m, 0)
            self.dev.syn()

    def ctrl_v(self) -> None:
        self.tap_key(KEY_V, ctrl=True)

    def type_text(self, text: str, delay: float = 0.003) -> tuple[int, int]:
        """Text ko keystrokes me type karta hai. Return: (typed, skipped)."""
        typed = skipped = 0
        for ch in text:
            mapping = keymap.CHAR_TO_KEY.get(ch)
            if mapping is None:
                skipped += 1
                continue
            code, needs_shift = mapping
            self.tap_key(code, shift=needs_shift)
            typed += 1
            if delay:
                time.sleep(delay)
        return typed, skipped

    def close(self) -> None:
        try:
            self.dev.close()
        except Exception:
            pass


class MockInjector:
    """Dry-run mode — /dev/uinput ke bina protocol test karne ke liye."""

    def __init__(self) -> None:
        self._lock = threading.Lock()

    def move(self, dx: int, dy: int) -> None:
        log.info("mock move dx=%s dy=%s", dx, dy)

    def scroll(self, dy: int = 0, dx: int = 0) -> None:
        log.info("mock scroll dy=%s dx=%s", dy, dx)

    def button(self, btn: str, action: str) -> None:
        log.info("mock button %s %s", btn, action)

    def tap_key(self, code, shift=False, ctrl=False, alt=False) -> None:
        log.info("mock key code=%s shift=%s ctrl=%s alt=%s", code, shift, ctrl, alt)

    def ctrl_v(self) -> None:
        log.info("mock ctrl+v")

    def type_text(self, text: str, delay: float = 0.0) -> tuple[int, int]:
        typed = sum(1 for ch in text if ch in keymap.CHAR_TO_KEY)
        log.info(
            "mock type %r (typed=%d skipped=%d)",
            text[:60], typed, len(text) - typed,
        )
        return typed, len(text) - typed

    def close(self) -> None:
        pass
