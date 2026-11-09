"""US QWERTY layout ke liye char -> (keycode, shift?) mapping."""

import string

from .uinput import (
    BTN_CODES,
    EV_KEY,
    EV_REL,
    KEY_CODES,
    REL_HWHEEL,
    REL_WHEEL,
    REL_X,
    REL_Y,
)


def _c(name: str) -> int:
    if name in KEY_CODES:
        return KEY_CODES[name]
    if name in BTN_CODES:
        return BTN_CODES[name]
    raise KeyError(name)


# a-z aur 0-9 bina shift ke
_PLAIN: dict[str, tuple[int, bool]] = {
    ch: (_c(f"KEY_{ch.upper()}"), False)
    for ch in string.ascii_lowercase + string.digits
}

# Shift ke saath type hone wale chars
_SHIFTED_SRC = {
    **{ch: f"KEY_{ch.upper()}" for ch in string.ascii_uppercase},
    "!": "KEY_1", "@": "KEY_2", "#": "KEY_3", "$": "KEY_4", "%": "KEY_5",
    "^": "KEY_6", "&": "KEY_7", "*": "KEY_8", "(": "KEY_9", ")": "KEY_0",
    "_": "KEY_MINUS", "+": "KEY_EQUAL",
    "{": "KEY_LEFTBRACE", "}": "KEY_RIGHTBRACE", "|": "KEY_BACKSLASH",
    ":": "KEY_SEMICOLON", '"': "KEY_APOSTROPHE", "~": "KEY_GRAVE",
    "<": "KEY_COMMA", ">": "KEY_DOT", "?": "KEY_SLASH",
}
_SHIFTED = {ch: (_c(name), True) for ch, name in _SHIFTED_SRC.items()}

# Plain punctuation + control chars
_PLAIN_PUNCT = {
    " ": "KEY_SPACE", "\t": "KEY_TAB",
    "-": "KEY_MINUS", "=": "KEY_EQUAL",
    "[": "KEY_LEFTBRACE", "]": "KEY_RIGHTBRACE", "\\": "KEY_BACKSLASH",
    ";": "KEY_SEMICOLON", "'": "KEY_APOSTROPHE", "`": "KEY_GRAVE",
    ",": "KEY_COMMA", ".": "KEY_DOT", "/": "KEY_SLASH",
}
_PLAIN.update({ch: (_c(name), False) for ch, name in _PLAIN_PUNCT.items()})

# Newline = Shift+Enter, taake chat apps text ko send na karein (sirf naya line ho)
_SHIFTED["\n"] = (_c("KEY_ENTER"), True)
_SHIFTED["\r"] = (_c("KEY_ENTER"), True)

CHAR_TO_KEY: dict[str, tuple[int, bool]] = {**_PLAIN, **_SHIFTED}

# App ke {"t":"key","k":"enter"} wale named keys
SPECIAL_KEYS: dict[str, int] = {
    name: _c(f"KEY_{name.upper()}")
    for name in (
        "enter", "esc", "tab", "space", "backspace", "delete", "insert",
        "up", "down", "left", "right", "home", "end", "pageup", "pagedown",
    )
}
SPECIAL_KEYS["escape"] = _c("KEY_ESC")
SPECIAL_KEYS.update({f"f{i}": _c(f"KEY_F{i}") for i in range(1, 13)})

MODIFIER_KEYS = (
    "KEY_LEFTCTRL", "KEY_RIGHTCTRL", "KEY_LEFTSHIFT", "KEY_RIGHTSHIFT",
    "KEY_LEFTALT", "KEY_RIGHTALT", "KEY_LEFTMETA", "KEY_RIGHTMETA",
)

MOUSE_BUTTONS = ("BTN_LEFT", "BTN_RIGHT", "BTN_MIDDLE", "BTN_SIDE", "BTN_EXTRA")


def capabilities() -> dict[int, list[int]]:
    """uinput device ke liye EV_KEY/EV_REL bits (hamesha keymap ka superset)."""
    key_bits = {code for code, _ in CHAR_TO_KEY.values()}
    key_bits.update(SPECIAL_KEYS.values())
    key_bits.update(_c(n) for n in MODIFIER_KEYS)
    key_bits.update(_c(n) for n in MOUSE_BUTTONS)
    return {
        EV_KEY: sorted(key_bits),
        EV_REL: [REL_X, REL_Y, REL_WHEEL, REL_HWHEEL],
    }
