#!/usr/bin/env python3
"""Wrap each raw mobile screenshot in a 1080x1920 (9:16) brand-coloured
canvas, satisfying Play Console's:
    - aspect ratio between 9:16 and 16:9 (raw shots are 9:19)
    - minimum 1080px on each side for promotion eligibility

Output:
    landing/screenshots/play/mobile-1-welcome.png   ... etc
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC  = ROOT / "landing" / "screenshots"
OUT  = SRC / "play"

W, H = 1080, 1920  # 9:16, ≥1080px each side

# Brand stops — match lib/core/theme/app_colors.dart
VIOLET     = (139, 92, 246)
PINK       = (236, 72, 153)
DEEP_PLUM  = (12, 6, 28)
DEEP_PLUM2 = (24, 14, 48)


def _radial_glow(size_px, color_rgb, alpha=140):
    s = size_px
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    px = img.load()
    cx, cy, rmax = s / 2, s / 2, s / 2
    for y in range(s):
        for x in range(s):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d >= rmax:
                continue
            t = (1.0 - d / rmax) ** 2
            px[x, y] = (*color_rgb, int(alpha * t))
    return img


def _backdrop():
    """Plum gradient with two soft glow blobs."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = (x + y) / (W + H - 2)
            r = int(DEEP_PLUM[0] + (DEEP_PLUM2[0] - DEEP_PLUM[0]) * t)
            g = int(DEEP_PLUM[1] + (DEEP_PLUM2[1] - DEEP_PLUM[1]) * t)
            b = int(DEEP_PLUM[2] + (DEEP_PLUM2[2] - DEEP_PLUM[2]) * t)
            px[x, y] = (r, g, b, 255)
    img.alpha_composite(_radial_glow(1100, VIOLET, alpha=110), (-200, -300))
    img.alpha_composite(_radial_glow(900, PINK, alpha=80), (W - 600, H - 700))
    return img


def _drop_shadow(img, offset=(0, 28), blur=36, alpha=210):
    pad = blur * 2
    canvas = Image.new(
        "RGBA",
        (img.width + pad * 2, img.height + pad * 2),
        (0, 0, 0, 0),
    )
    alpha_mask = img.split()[-1]
    shadow = Image.new("RGBA", img.size, (0, 0, 0, alpha))
    shadow.putalpha(alpha_mask)
    canvas.paste(shadow, (pad + offset[0], pad + offset[1]), shadow)
    canvas = canvas.filter(ImageFilter.GaussianBlur(radius=blur))
    canvas.paste(img, (pad, pad), img)
    return canvas, pad


def _round_corners(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (img.width - 1, img.height - 1)],
        radius=radius,
        fill=255,
    )
    img.putalpha(mask)
    return img


def _wrap_one(src_path, dst_path):
    bg = _backdrop()

    # Load + scale the screenshot to fit the canvas height with margin.
    shot = Image.open(src_path).convert("RGBA")
    target_h = int(H * 0.94)  # leave a 3% strip top + bottom
    scale = target_h / shot.height
    new_w = int(shot.width * scale)
    new_h = target_h
    shot = shot.resize((new_w, new_h), Image.LANCZOS)

    # If the scaled shot is wider than the canvas, scale it down further.
    if new_w > W - 80:
        scale2 = (W - 80) / new_w
        shot = shot.resize((int(new_w * scale2), int(new_h * scale2)), Image.LANCZOS)

    # Round the screenshot corners so it reads as a "phone screen".
    shot = _round_corners(shot, radius=48)

    # Drop shadow + composite onto centre of backdrop.
    shadowed, pad = _drop_shadow(shot, offset=(0, 30), blur=40, alpha=200)
    x = (W - shot.width) // 2 - pad
    y = (H - shot.height) // 2 - pad
    bg.alpha_composite(shadowed, (x, y))

    bg.convert("RGB").save(dst_path, "PNG", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    sources = sorted(SRC.glob("mobile-*.jpg"))
    if not sources:
        raise SystemExit(f"No mobile-*.jpg found in {SRC}")
    for src in sources:
        dst = OUT / (src.stem + ".png")
        _wrap_one(src, dst)
        print(f"  {src.name}  →  {dst.relative_to(ROOT)}")
    print(f"\n✅ Wrote {len(sources)} Play-ready screenshots to {OUT}")


if __name__ == "__main__":
    main()
