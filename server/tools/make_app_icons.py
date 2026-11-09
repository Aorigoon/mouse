#!/usr/bin/env python3
"""Mousify app launcher icons generate karta hai (1024px, Android adaptive).

Usage: venv-python tools/make_app_icons.py
Output: app/assets/icon/mousify_foreground.png + mousify_legacy.png
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
# script: <repo>/server/tools/ → target: <repo>/app/assets/icon/
OUT_DIR = Path(__file__).resolve().parent.parent.parent / "app" / "assets" / "icon"


def draw_glyph(d: ImageDraw.ImageDraw, s: float, color) -> None:
    """Mouse glyph — body + divider line, 256-grid ke coords * s par."""
    # body: rounded rect (256-grid: 88,56,168,200)
    body = [88 * s, 56 * s, 168 * s, 200 * s]
    d.rounded_rectangle(body, radius=40 * s, outline=color, width=int(10 * s))
    # divider: top-half vertical line
    d.line(
        [(128 * s, 62 * s), (128 * s, 118 * s)],
        fill=color, width=int(10 * s),
    )


def make_foreground() -> None:
    """Adaptive icon foreground — transparent bg, white glyph center 40% me."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = SIZE / 256 * 1.0
    # glyph ko center karo: glyph box = 88..168 x (256-grid) → center 128,128 hai already
    draw_glyph(d, s, (255, 255, 255, 255))
    img.save(OUT_DIR / "mousify_foreground.png")
    print("saved mousify_foreground.png")


def make_legacy() -> None:
    """Legacy icon — black rounded square + white glyph (mask se pehle ka look)."""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(
        [0, 0, SIZE, SIZE], radius=int(SIZE * 0.22), fill=(0, 0, 0, 255)
    )
    draw_glyph(d, SIZE / 256, (255, 255, 255, 255))
    img.save(OUT_DIR / "mousify_legacy.png")
    print("saved mousify_legacy.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    make_foreground()
    make_legacy()


if __name__ == "__main__":
    main()
