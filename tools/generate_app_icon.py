#!/usr/bin/env python3
"""Render the TouchifyMouse master app icon at 1024x1024 + a tray-friendly
1024x1024 white-on-transparent variant.

Usage:
    python3 tools/generate_app_icon.py
        --> writes assets/branding/app_icon.png
                   assets/branding/tray_icon.png

The PIL "image" mode is RGBA. We draw a rounded-square base filled with the
violet→pink brand gradient and overlay a stylised "mouse" silhouette in
white. For tray we render the silhouette only on transparent so it adapts to
both light and dark menu bars.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT       = Path(__file__).resolve().parent.parent
OUT_DIR    = ROOT / "assets" / "branding"
SIZE       = 1024
RADIUS     = 224  # iOS-ish "squircle" feel without computing a real squircle
INSET      = 28   # margin between icon edge and gradient base

# Brand stops — match lib/core/theme/app_colors.dart
VIOLET = (139, 92, 246)   # #8B5CF6
PINK   = (236,  72, 153)  # #EC4899


def _gradient_base(size, radius):
    """Square RGBA image with diagonal violet→pink gradient, rounded corners."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px  = img.load()
    # Diagonal: t = (x + y) / (2 * size)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 2)
            r = int(VIOLET[0] + (PINK[0] - VIOLET[0]) * t)
            g = int(VIOLET[1] + (PINK[1] - VIOLET[1]) * t)
            b = int(VIOLET[2] + (PINK[2] - VIOLET[2]) * t)
            px[x, y] = (r, g, b, 255)

    # Round the corners by masking.
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (size - 1, size - 1)], radius=radius, fill=255,
    )
    rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    rounded.paste(img, (0, 0), mask=mask)
    return rounded


def _mouse_path(size, color):
    """Mouse silhouette in `color` on transparent. Plain pill shape with a
    vertical scroll-wheel notch at the top. Designed to read well even at
    16x16 (tray)."""
    img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d    = ImageDraw.Draw(img)

    # Mouse body — pill (rounded rect with very high radius).
    margin_x = int(size * 0.30)
    margin_y_top = int(size * 0.18)
    margin_y_bot = int(size * 0.12)
    body_w = size - 2 * margin_x
    body_h = size - margin_y_top - margin_y_bot

    d.rounded_rectangle(
        [
            (margin_x, margin_y_top),
            (margin_x + body_w, margin_y_top + body_h),
        ],
        radius=int(body_w * 0.50),
        fill=color,
    )

    # Scroll wheel — small rounded rect, slightly above body center.
    wheel_w = int(body_w * 0.10)
    wheel_h = int(body_h * 0.20)
    cx = size // 2
    wheel_top = margin_y_top + int(body_h * 0.15)
    d.rounded_rectangle(
        [
            (cx - wheel_w // 2, wheel_top),
            (cx + wheel_w // 2, wheel_top + wheel_h),
        ],
        radius=wheel_w // 2,
        # Subtract the wheel by drawing it transparent — actually we want
        # the wheel a darker shade on the gradient version, so we just
        # punch a hole here and let the caller decide what to put behind.
        fill=(0, 0, 0, 0),
    )
    return img


def _composite_app_icon():
    base = _gradient_base(SIZE, RADIUS)

    # Mouse silhouette in white, slightly inset so the gradient breathes.
    mouse_canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(mouse_canvas)

    margin_x = int(SIZE * 0.32)
    margin_y_top = int(SIZE * 0.20)
    margin_y_bot = int(SIZE * 0.14)
    body_w = SIZE - 2 * margin_x
    body_h = SIZE - margin_y_top - margin_y_bot

    # White body with a subtle drop shadow for depth.
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        [
            (margin_x, margin_y_top + 14),
            (margin_x + body_w, margin_y_top + body_h + 14),
        ],
        radius=int(body_w * 0.50),
        fill=(0, 0, 0, 90),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=12))
    base = Image.alpha_composite(base, shadow)

    d.rounded_rectangle(
        [
            (margin_x, margin_y_top),
            (margin_x + body_w, margin_y_top + body_h),
        ],
        radius=int(body_w * 0.50),
        fill=(255, 255, 255, 255),
    )

    # Scroll wheel — violet so it looks like part of the brand.
    wheel_w = int(body_w * 0.11)
    wheel_h = int(body_h * 0.22)
    cx = SIZE // 2
    wheel_top = margin_y_top + int(body_h * 0.16)
    d.rounded_rectangle(
        [
            (cx - wheel_w // 2, wheel_top),
            (cx + wheel_w // 2, wheel_top + wheel_h),
        ],
        radius=wheel_w // 2,
        fill=VIOLET,
    )

    return Image.alpha_composite(base, mouse_canvas)


def _tray_icon():
    """Small brand-coloured tray icon — gradient rounded square + white
    mouse silhouette. Reads on both light and dark macOS menu bars (a
    pure-white silhouette would be invisible on a light menu bar; a pure
    dark one would be invisible on dark mode)."""
    # Same composition as the app icon but tighter padding so it doesn't
    # look like dead space in the 22px-tall menu bar.
    out = SIZE
    base = Image.new("RGBA", (out, out), (0, 0, 0, 0))

    # Gradient rounded square (slightly inset so corners don't clip).
    grad = Image.new("RGBA", (out, out), (0, 0, 0, 0))
    px = grad.load()
    inset = int(out * 0.04)
    for y in range(out):
        for x in range(out):
            t = (x + y) / (2 * out - 2)
            r = int(VIOLET[0] + (PINK[0] - VIOLET[0]) * t)
            g = int(VIOLET[1] + (PINK[1] - VIOLET[1]) * t)
            b = int(VIOLET[2] + (PINK[2] - VIOLET[2]) * t)
            px[x, y] = (r, g, b, 255)
    mask = Image.new("L", (out, out), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(inset, inset), (out - 1 - inset, out - 1 - inset)],
        radius=int(out * 0.26),
        fill=255,
    )
    base.paste(grad, (0, 0), mask=mask)

    # White mouse silhouette.
    fg = Image.new("RGBA", (out, out), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    mx = int(out * 0.30)
    my_top = int(out * 0.20)
    my_bot = int(out * 0.16)
    bw = out - 2 * mx
    bh = out - my_top - my_bot
    d.rounded_rectangle(
        [(mx, my_top), (mx + bw, my_top + bh)],
        radius=int(bw * 0.50),
        fill=(255, 255, 255, 255),
    )
    # Wheel — kept violet so it pops against the white body.
    ww = int(bw * 0.12)
    wh = int(bh * 0.22)
    cx = out // 2
    wt = my_top + int(bh * 0.16)
    d.rounded_rectangle(
        [(cx - ww // 2, wt), (cx + ww // 2, wt + wh)],
        radius=ww // 2,
        fill=VIOLET,
    )
    return Image.alpha_composite(base, fg)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    app = _composite_app_icon()
    tray = _tray_icon()
    app.save(OUT_DIR / "app_icon.png", "PNG", optimize=True)
    tray.save(OUT_DIR / "tray_icon.png", "PNG", optimize=True)
    print(f"Wrote {OUT_DIR / 'app_icon.png'}")
    print(f"Wrote {OUT_DIR / 'tray_icon.png'}")


if __name__ == "__main__":
    main()
