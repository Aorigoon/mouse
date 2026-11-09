#!/usr/bin/env python3
"""Mousify icon generate karta hai (B&W minimal — mouse glyph).

Usage: venv-python tools/make_icon.py [output.png]
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 256
OUT = sys.argv[1] if len(sys.argv) > 1 else str(
    Path(__file__).resolve().parent.parent / "assets" / "mousify_icon.png"
)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # black rounded square background
    d.rounded_rectangle([12, 12, SIZE - 12, SIZE - 12], radius=56, fill=(0, 0, 0, 255))

    # mouse body — white outline ellipse (vertical)
    body = [88, 56, 168, 200]
    d.rounded_rectangle(body, radius=40, outline=(255, 255, 255, 255), width=10)

    # left/right divider (top half me vertical line)
    d.line([(128, 60), (128, 118)], fill=(255, 255, 255, 255), width=10)

    Path(OUT).parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(f"icon saved: {OUT}")


if __name__ == "__main__":
    main()
