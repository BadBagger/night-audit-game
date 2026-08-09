from __future__ import annotations

from pathlib import Path
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter


REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / "art" / "source" / "blockouts" / "chapter1" / "mick_tarp_body"
DEST = REPO / "art" / "reusable" / "props" / "mick_tarp_body"


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * max(0.0, min(1.0, t)))


def crop_to_alpha(image: Image.Image, margin: int = 22) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("empty alpha")
    left, top, right, bottom = bbox
    left = max(0, left - margin)
    top = max(0, top - margin)
    right = min(image.width, right + margin)
    bottom = min(image.height, bottom + margin)
    return image.crop((left, top, right, bottom))


def main() -> int:
    rng = random.Random(91723)
    mask = Image.open(SOURCE / "mick_tarp_body_mask.png").convert("L")
    depth = Image.open(SOURCE / "mick_tarp_body_depth.png").convert("L")
    width, height = mask.size

    body_alpha = mask.point(lambda p: 255 if p >= 32 else 0)
    body_alpha = body_alpha.filter(ImageFilter.GaussianBlur(0.55)).point(lambda p: min(255, round(p * 1.25)))

    base = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pixels = base.load()
    mask_px = body_alpha.load()
    depth_px = depth.load()

    for y in range(height):
        for x in range(width):
            a = mask_px[x, y]
            if a <= 0:
                continue
            d = depth_px[x, y] / 255.0
            cool_shadow = 1.0 - (y / max(1, height - 1)) * 0.16
            side_shadow = 1.0 - abs((x / max(1, width - 1)) - 0.52) * 0.18
            n = rng.randint(-13, 13)
            r = lerp(35, 86, d) + n
            g = lerp(44, 98, d) + n
            b = lerp(48, 104, d) + n
            r = round(r * cool_shadow * side_shadow)
            g = round(g * cool_shadow * side_shadow)
            b = round(b * cool_shadow)
            pixels[x, y] = (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), a)

    # Soft painterly blending without losing the validated binary silhouette.
    painted = base.filter(ImageFilter.GaussianBlur(0.65))
    painted.putalpha(body_alpha)

    shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    shadow_alpha = body_alpha.filter(ImageFilter.GaussianBlur(8))
    shadow_alpha = ImageChops.offset(shadow_alpha, 12, 12).point(lambda p: round(p * 0.32))
    shadow.putalpha(shadow_alpha)

    outline = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    dilated = body_alpha.filter(ImageFilter.MaxFilter(9))
    edge = ImageChops.subtract(dilated, body_alpha.filter(ImageFilter.MinFilter(3)))
    outline.putalpha(edge.point(lambda p: round(p * 0.55)))

    highlight = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(highlight)
    fold_lines = [
        (312, 348, 376, 536, 2),
        (404, 338, 472, 546, 2),
        (508, 334, 592, 558, 2),
        (652, 334, 734, 552, 2),
        (780, 342, 866, 548, 2),
        (876, 346, 946, 526, 2),
        (970, 348, 1034, 520, 2),
    ]
    for x1, y1, x2, y2, w in fold_lines:
        draw.line((x1, y1, x2, y2), fill=(128, 160, 176, 78), width=w)
        draw.line((x1 + 7, y1 + 6, x2 + 9, y2 + 7), fill=(10, 18, 22, 96), width=max(1, w))

    for _ in range(180):
        x = rng.randrange(150, 1080)
        y = rng.randrange(292, 560)
        if body_alpha.getpixel((x, y)) < 32:
            continue
        strength = rng.randrange(18, 52)
        draw.ellipse((x, y, x + rng.randrange(1, 4), y + rng.randrange(1, 3)), fill=(170, 185, 184, strength))

    highlight.putalpha(ImageChops.multiply(highlight.getchannel("A"), body_alpha))
    composite = Image.alpha_composite(shadow, outline)
    composite = Image.alpha_composite(composite, painted)
    composite = Image.alpha_composite(composite, highlight.filter(ImageFilter.GaussianBlur(0.35)))

    # Hard-mask final alpha from the validated source, with only a small feather.
    final_alpha = body_alpha.filter(ImageFilter.GaussianBlur(0.35)).point(lambda p: 255 if p >= 40 else 0)
    composite.putalpha(final_alpha)

    DEST.mkdir(parents=True, exist_ok=True)
    full = DEST / "mick_tarp_body_iso.png"
    trim = DEST / "mick_tarp_body_trim.png"
    composite.save(full)
    crop_to_alpha(composite).save(trim)
    print(f"wrote {full.relative_to(REPO)}")
    print(f"wrote {trim.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
