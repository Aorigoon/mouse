"""Pure-Python /dev/uinput driver — koi C extension nahi (evdev ki zarurat nahi).

Kernel ABI constants (linux/input-event-codes.h + linux/uinput.h) — stable hain.
Sirf x86_64/aarch64 jaise 64-bit Linux ke liye (input_event = 24 bytes).
"""

import fcntl
import os
import struct

# --- event types ----------------------------------------------------------
EV_SYN = 0x00
EV_KEY = 0x01
EV_REL = 0x02

SYN_REPORT = 0

# --- relative axes --------------------------------------------------------
REL_X = 0x00
REL_Y = 0x01
REL_HWHEEL = 0x06
REL_WHEEL = 0x08

# --- mouse buttons --------------------------------------------------------
BTN_LEFT = 0x110
BTN_RIGHT = 0x111
BTN_MIDDLE = 0x112
BTN_SIDE = 0x113
BTN_EXTRA = 0x114

BTN_CODES: dict[str, int] = {
    "BTN_LEFT": BTN_LEFT,
    "BTN_RIGHT": BTN_RIGHT,
    "BTN_MIDDLE": BTN_MIDDLE,
    "BTN_SIDE": BTN_SIDE,
    "BTN_EXTRA": BTN_EXTRA,
}

# --- keycodes (kernel input-event-codes.h) --------------------------------
KEY_CODES: dict[str, int] = {
    "KEY_ESC": 1,
    "KEY_1": 2, "KEY_2": 3, "KEY_3": 4, "KEY_4": 5, "KEY_5": 6,
    "KEY_6": 7, "KEY_7": 8, "KEY_8": 9, "KEY_9": 10, "KEY_0": 11,
    "KEY_MINUS": 12, "KEY_EQUAL": 13, "KEY_BACKSPACE": 14, "KEY_TAB": 15,
    "KEY_Q": 16, "KEY_W": 17, "KEY_E": 18, "KEY_R": 19, "KEY_T": 20,
    "KEY_Y": 21, "KEY_U": 22, "KEY_I": 23, "KEY_O": 24, "KEY_P": 25,
    "KEY_LEFTBRACE": 26, "KEY_RIGHTBRACE": 27, "KEY_ENTER": 28, "KEY_LEFTCTRL": 29,
    "KEY_A": 30, "KEY_S": 31, "KEY_D": 32, "KEY_F": 33, "KEY_G": 34,
    "KEY_H": 35, "KEY_J": 36, "KEY_K": 37, "KEY_L": 38,
    "KEY_SEMICOLON": 39, "KEY_APOSTROPHE": 40, "KEY_GRAVE": 41,
    "KEY_LEFTSHIFT": 42, "KEY_BACKSLASH": 43,
    "KEY_Z": 44, "KEY_X": 45, "KEY_C": 46, "KEY_V": 47, "KEY_B": 48,
    "KEY_N": 49, "KEY_M": 50,
    "KEY_COMMA": 51, "KEY_DOT": 52, "KEY_SLASH": 53, "KEY_RIGHTSHIFT": 54,
    "KEY_LEFTALT": 56, "KEY_SPACE": 57, "KEY_CAPSLOCK": 58,
    "KEY_F1": 59, "KEY_F2": 60, "KEY_F3": 61, "KEY_F4": 62, "KEY_F5": 63,
    "KEY_F6": 64, "KEY_F7": 65, "KEY_F8": 66, "KEY_F9": 67, "KEY_F10": 68,
    "KEY_RIGHTCTRL": 97, "KEY_RIGHTALT": 100,
    "KEY_HOME": 102, "KEY_UP": 103, "KEY_PAGEUP": 104,
    "KEY_LEFT": 105, "KEY_RIGHT": 106, "KEY_END": 107,
    "KEY_DOWN": 108, "KEY_PAGEDOWN": 109, "KEY_INSERT": 110, "KEY_DELETE": 111,
    "KEY_F11": 87, "KEY_F12": 88,
    "KEY_LEFTMETA": 125, "KEY_RIGHTMETA": 126,
}

# injector ke liye aam module-level aliases
KEY_LEFTCTRL = KEY_CODES["KEY_LEFTCTRL"]
KEY_LEFTSHIFT = KEY_CODES["KEY_LEFTSHIFT"]
KEY_LEFTALT = KEY_CODES["KEY_LEFTALT"]
KEY_V = KEY_CODES["KEY_V"]


def _iow(typ: str, nr: int, size: int) -> int:
    return (1 << 30) | (size << 16) | (ord(typ) << 8) | nr


def _io(typ: str, nr: int) -> int:
    return (ord(typ) << 8) | nr


UI_SET_EVBIT = _iow("U", 100, 4)
UI_SET_KEYBIT = _iow("U", 101, 4)
UI_SET_RELBIT = _iow("U", 102, 4)
UI_DEV_CREATE = _io("U", 1)
UI_DEV_DESTROY = _io("U", 2)

_BUS_USB = 0x03
_UINPUT_MAX_NAME = 80
# struct uinput_user_dev: name[80] + input_id(4x u16) + ff_effects_max(u32) + 4x64 s32
_DEV_STRUCT = struct.Struct(f"{_UINPUT_MAX_NAME}s4Hi64i64i64i64i")
# struct input_event (64-bit): timeval(2x long) + type(u16) + code(u16) + value(s32)
_EVENT_STRUCT = struct.Struct("=qqHHi")


class UInputDevice:
    """Kernel-level virtual input device (mouse + keyboard combo)."""

    def __init__(
        self,
        key_bits: list[int],
        rel_bits: list[int],
        name: str = "Mousify Virtual Input",
    ) -> None:
        self._fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
        try:
            fcntl.ioctl(self._fd, UI_SET_EVBIT, EV_KEY)
            fcntl.ioctl(self._fd, UI_SET_EVBIT, EV_REL)
            for bit in set(key_bits):
                fcntl.ioctl(self._fd, UI_SET_KEYBIT, bit)
            for bit in set(rel_bits):
                fcntl.ioctl(self._fd, UI_SET_RELBIT, bit)

            ident = _DEV_STRUCT.pack(
                name.encode("utf-8")[:_UINPUT_MAX_NAME].ljust(_UINPUT_MAX_NAME, b"\0"),
                _BUS_USB, 0x1234, 0x5678, 1, 0,
                *([0] * 256),
            )
            os.write(self._fd, ident)
            fcntl.ioctl(self._fd, UI_DEV_CREATE)
        except Exception:
            os.close(self._fd)
            raise

    def write_event(self, type_: int, code: int, value: int) -> None:
        os.write(self._fd, _EVENT_STRUCT.pack(0, 0, type_, code, value))

    def syn(self) -> None:
        self.write_event(EV_SYN, SYN_REPORT, 0)

    def close(self) -> None:
        if self._fd >= 0:
            try:
                fcntl.ioctl(self._fd, UI_DEV_DESTROY)
            except OSError:
                pass
            os.close(self._fd)
            self._fd = -1
