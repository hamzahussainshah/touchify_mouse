#!/usr/bin/env python3
"""Render the Play Console feature graphic (1024x500).

Usage:
    python3 tools/generate_feature_graphic.py
        --> writes assets/branding/feature_graphic.png

Layout: brand gradient backdrop with soft glow blobs, the rounded
"app icon" logo on the left, and product copy on the right.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT     = Path(__file__).resolve().parent.parent
OUT      = ROOT / "assets" / "branding" / "feature_graphic.png"
APP_ICON = ROOT / "assets" / "branding" / "app_icon.png"

W, H = 1024, 500

# Brand stops — match lib/core/theme/app_colors.dart
VIOLET     = (139, 92, 246)
PINK       = (236, 72, 153)
DEEP_PLUM  = (12, 6, 28)
DEEP_PLUM2 = (24, 14, 48)
WHITE      = (255, 255, 255)
TEXT_DIM   = (220, 218, 240)


# ── Helpers ──────────────────────────────────────────────────────────────────

def _radial_glow(size_px, color_rgb, alpha=180):
    """Returns an RGBA image of a soft circular glow."""
    s = size_px
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    px = img.load()
    cx, cy = s / 2, s / 2
    r_max = s / 2
    for y in range(s):
        for x in range(s):
            dx, dy = x - cx, y - cy
            d = (dx * dx + dy * dy) ** 0.5
            if d >= r_max:
                continue
            t = 1.0 - (d / r_max)
            t = t ** 2  # softer edge
            a = int(alpha * t)
            px[x, y] = (*color_rgb, a)
    return img


def _backdrop():
    """Diagonal gradient + a few coloured glow blobs."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = (x + y) / (W + H - 2)
            r = int(DEEP_PLUM[0] + (DEEP_PLUM2[0] - DEEP_PLUM[0]) * t)
            g = int(DEEP_PLUM[1] + (DEEP_PLUM2[1] - DEEP_PLUM[1]) * t)
            b = int(DEEP_PLUM[2] + (DEEP_PLUM2[2] - DEEP_PLUM[2]) * t)
            px[x, y] = (r, g, b, 255)

    # Two soft glow blobs — violet upper-left, pink lower-right.
    violet_glow = _radial_glow(700, VIOLET, alpha=110)
    pink_glow = _radial_glow(620, PINK, alpha=85)
    img.alpha_composite(violet_glow, (-180, -260))
    img.alpha_composite(pink_glow, (W - 460, H - 360))
    return img


def _rounded_app_icon(size):
    """Use the existing 1024 master, downscaled — guarantees the listing
    icon and feature graphic stay perfectly in sync."""
    if not APP_ICON.exists():
        raise SystemExit(
            f"Missing {APP_ICON} — run tools/generate_app_icon.py first."
        )
    src = Image.open(APP_ICON).convert("RGBA")
    return src.resize((size, size), Image.LANCZOS)


def _drop_shadow(img, offset=(0, 18), blur=24, alpha=180):
    """Soft drop shadow under an RGBA sprite, returned as a new RGBA image
    sized to fit the original + extra room for the blur."""
    pad = blur * 2
    canvas = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))

    # Black silhouette using the alpha channel
    alpha_mask = img.split()[-1]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, alpha))
    shadow.putalpha(alpha_mask)

    canvas.paste(shadow, (pad + offset[0], pad + offset[1]), shadow)
    canvas = canvas.filter(ImageFilter.GaussianBlur(radius=blur))
    canvas.paste(img, (pad, pad), img)
    return canvas, pad


def _font(size, bold=False):
    """macOS-friendly font fallback chain."""
    candidates_bold = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    candidates_reg = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in (candidates_bold if bold else candidates_reg):
        try:
            return ImageFont.truetype(p, size)
        except (OSError, ValueError):
            continue
    return ImageFont.load_default()


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bg = _backdrop()
    d = ImageDraw.Draw(bg)

    # ── Left side: app icon with shadow ──
    icon_size = 280
    icon = _rounded_app_icon(icon_size)
    icon_with_shadow, pad = _drop_shadow(icon, offset=(0, 22), blur=28, alpha=200)
    icon_x = 70 - pad
    icon_y = (H - icon_size) // 2 - pad
    bg.alpha_composite(icon_with_shadow, (icon_x, icon_y))

    # ── Right side: text block ──
    text_x = 410
    # Brand wordmark
    d.text(
        (text_x, 102),
        "TouchifyMouse",
        font=_font(34, bold=True),
        fill=(255, 255, 255, 255),
    )

    # Headline (two lines)
    d.text(
        (text_x, 158),
        "Your phone is now",
        font=_font(46, bold=True),
        fill=(255, 255, 255, 255),
    )
    # Second line — gradient effect via two-tone overlay isn't trivial
    # without a shader; using accent pink for a clear visual hit.
    d.text(
        (text_x, 218),
        "a wireless trackpad.",
        font=_font(46, bold=True),
        fill=PINK + (255,),
    )

    # Sub-headline
    d.text(
        (text_x, 296),
        "Trackpad · Keyboard · Media · Mic & Speaker",
        font=_font(20, bold=False),
        fill=TEXT_DIM + (255,),
    )

    # Tagline (no pill — PIL won't blend alpha into the background reliably,
    # so drawing text straight on the gradient looks cleaner)
    d.text(
        (text_x, 354),
        "FREE  ·  NO ACCOUNT  ·  LOCAL WI-FI",
        font=_font(14, bold=True),
        fill=(196, 181, 253, 255),  # primaryDim (#C4B5FD)
    )

    # ── Save ──
    bg.convert("RGB").save(OUT, "PNG", optimize=True)
    print(f"Wrote {OUT}  ({W}x{H})")


if __name__ == "__main__":
    main()
