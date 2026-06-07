"""Regenerate assets/icon/app_icon.png — square, black bleed, no stretch."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
BLUE = (56, 189, 248, 255)
OUT = Path(__file__).resolve().parents[1] / "assets" / "icon" / "app_icon.png"


def arc_points(
    cx: float,
    cy: float,
    r: float,
    a0: float,
    a1: float,
    steps: int,
) -> list[tuple[float, float]]:
    """Points along a circular arc from a0 to a1 (radians), counter-clockwise."""
    pts: list[tuple[float, float]] = []
    if a1 < a0:
        a1 += 2 * math.pi
    for i in range(steps):
        t = i / max(steps - 1, 1)
        a = a0 + (a1 - a0) * t
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def keyhole_outline(cx: float, cy: float, scale: float) -> list[tuple[float, float]]:
    r = 198 * scale
    top_w = 66 * scale
    bot_w = 198 * scale
    slot_h = 215 * scale

    jy = cy + math.sqrt(max(r * r - top_w * top_w, 1))
    left = (cx - top_w, jy)
    right = (cx + top_w, jy)
    slot_bot_y = jy + slot_h

    a_left = math.atan2(left[1] - cy, left[0] - cx)
    a_right = math.atan2(right[1] - cy, right[0] - cx)

    pts = arc_points(cx, cy, r, a_left, a_right + 2 * math.pi, 88)
    pts.append(right)
    pts.append((cx + bot_w, slot_bot_y))
    pts.append((cx - bot_w, slot_bot_y))
    pts.append(left)
    return pts


def draw_glow_layer(
    size: int,
    cx: float,
    cy: float,
    scale: float,
    width: int,
    alpha: int,
) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.polygon(
        keyhole_outline(cx, cy, scale),
        outline=(*BLUE[:3], alpha),
        width=width,
    )
    return layer


def main() -> None:
    base = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))
    cx, cy = SIZE / 2, SIZE / 2 - 42
    scale = 1.0

    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    for w, alpha in [(30, 30), (24, 50), (18, 85), (14, 120)]:
        glow.alpha_composite(draw_glow_layer(SIZE, cx, cy, scale, w, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=8))
    base.alpha_composite(glow)

    draw = ImageDraw.Draw(base)
    draw.polygon(keyhole_outline(cx, cy, scale), outline=BLUE, width=14)

    lens_cy = cy - 6 * scale
    for radius, stroke in [(115 * scale, 10), (70 * scale, 8)]:
        draw.ellipse(
            [
                cx - radius,
                lens_cy - radius,
                cx + radius,
                lens_cy + radius,
            ],
            outline=BLUE,
            width=int(stroke),
        )

    dot_r = 24 * scale
    draw.ellipse(
        [cx - dot_r, lens_cy - dot_r, cx + dot_r, lens_cy + dot_r],
        fill=BLUE,
    )

    flat = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    flat.paste(base, mask=base.split()[3])
    OUT.parent.mkdir(parents=True, exist_ok=True)
    flat.save(OUT, format="PNG", optimize=True)
    print(f"Wrote {OUT} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
