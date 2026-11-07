#!/usr/bin/env python3
"""Draws the app icon (a green rounded square with a white tick) and writes
the Windows .ico, the macOS app icons, the Linux icon and the web icons. Run from the app folder:
    python3 tool/make_icons.py
Needs Pillow. The output files are committed; this script is how they were made."""
from pathlib import Path

from PIL import Image, ImageDraw

GREEN = (47, 125, 109, 255)
LIGHT = (164, 242, 224, 255)
WHITE = (255, 255, 255, 255)


def icon(size: int, maskable: bool = False, margin: float = 0.0) -> Image.Image:
    scale = 4  # draw large, then shrink for smooth edges
    s = size * scale
    if margin:
        inner = icon(round(size * (1 - 2 * margin)))
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        off = (size - inner.width) // 2
        canvas.paste(inner, (off, off), inner)
        return canvas
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if maskable:
        d.rectangle([0, 0, s, s], fill=GREEN)
        inset = s * 0.18
    else:
        r = s * 0.22
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=r, fill=GREEN)
        inset = s * 0.0
    # Three list lines on the left, a tick on the right of the top line.
    def p(x, y):
        return (inset + x * (s - 2 * inset), inset + y * (s - 2 * inset))

    w = max(1, int((s - 2 * inset) * 0.085))
    for i, y in enumerate((0.36, 0.54, 0.72)):
        x0 = 0.42 if i == 0 else 0.22
        d.line([p(x0, y), p(0.80, y)], fill=LIGHT if i else WHITE, width=w)
    # Tick before the first line.
    d.line([p(0.16, 0.33), p(0.24, 0.42), p(0.36, 0.24)], fill=WHITE, width=w, joint="curve")
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    sizes = [16, 24, 32, 48, 64, 128, 256]
    big = icon(256)
    big.save(root / "windows/runner/resources/app_icon.ico", sizes=[(n, n) for n in sizes])
    icon(16).save(root / "web/favicon.png")
    icon(192).save(root / "web/icons/Icon-192.png")
    icon(512).save(root / "web/icons/Icon-512.png")
    icon(192, maskable=True).save(root / "web/icons/Icon-maskable-192.png")
    # macOS icons leave a transparent margin like other Mac apps.
    mac = root / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for n in (16, 32, 64, 128, 256, 512, 1024):
        icon(n, margin=0.09).save(mac / f"app_icon_{n}.png")
    icon(256).save(root / "packaging/linux/gunluk-gorevler.png")
    icon(512, maskable=True).save(root / "web/icons/Icon-maskable-512.png")


if __name__ == "__main__":
    main()
