from __future__ import annotations

from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageFilter


REPO = Path(__file__).resolve().parents[1]
ROOT = REPO / "art" / "reusable"


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.strip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def save_trimmed(im: Image.Image, path: Path, margin: int = 16) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bbox = im.getchannel("A").getbbox()
    if bbox:
        l, t, r, b = bbox
        im = im.crop((max(0, l - margin), max(0, t - margin), min(im.width, r + margin), min(im.height, b + margin)))
    im.save(path)


def noise_overlay(im: Image.Image, mask: Image.Image, seed: int, strength: int = 18) -> None:
    rng = random.Random(seed)
    px = im.load()
    mp = mask.load()
    for y in range(im.height):
        for x in range(im.width):
            if mp[x, y] == 0:
                continue
            r, g, b, a = px[x, y]
            n = rng.randint(-strength, strength)
            px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)), a)


def make_paper(asset_id: str, variant: str, seed: int, lines: int = 7, stamp: bool = False) -> None:
    rng = random.Random(seed)
    im = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pts = [(132, 90), (390, 116), (362, 416), (106, 382)]
    d.polygon(pts, fill=rgba("c9bea0", 242), outline=rgba("1e1914", 210))
    for _ in range(18):
        x = rng.randint(118, 380)
        y = rng.randint(108, 390)
        rr = rng.randint(14, 48)
        d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=rgba("6f7d7d", rng.randint(18, 48)))
    for i in range(lines):
        y = 142 + i * rng.randint(22, 32)
        x0 = rng.randint(150, 178)
        x1 = rng.randint(275, 345)
        d.line((x0, y, x1, y + rng.randint(-7, 8)), fill=rgba("343a36", rng.randint(95, 145)), width=rng.randint(3, 6))
    if stamp:
        d.rounded_rectangle((245, 295, 345, 342), radius=5, outline=rgba("772d24", 160), width=4)
        d.line((255, 318, 333, 322), fill=rgba("772d24", 120), width=4)
    im = im.filter(ImageFilter.GaussianBlur(0.25))
    save_trimmed(im, ROOT / "paper" / asset_id / f"{variant}.png")


def make_book(asset_id: str, variant: str, seed: int, open_book: bool = False) -> None:
    rng = random.Random(seed)
    im = Image.new("RGBA", (640, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if open_book:
        d.polygon([(120, 120), (310, 90), (314, 390), (110, 420)], fill=rgba("bbb194", 245), outline=rgba("211a15", 230))
        d.polygon([(318, 90), (520, 126), (518, 420), (314, 390)], fill=rgba("d0c6aa", 245), outline=rgba("211a15", 230))
        d.line((315, 94, 315, 392), fill=rgba("49372a", 180), width=5)
        for side in [0, 1]:
            for i in range(9):
                y = 140 + i * 24
                x0 = 150 if side == 0 else 350
                d.line((x0, y, x0 + rng.randint(70, 135), y + rng.randint(-3, 4)), fill=rgba("3e413c", 105), width=3)
    else:
        cover = rgba("3b3427", 245) if "ledger" in asset_id else rgba("6f563b", 245)
        d.rounded_rectangle((140, 115, 500, 388), radius=18, fill=cover, outline=rgba("1b1511", 240), width=5)
        d.rectangle((162, 137, 478, 366), outline=rgba("98784c", 130), width=5)
        d.rectangle((454, 120, 500, 385), fill=rgba("b09052", 165))
        d.line((460, 160, 493, 160), fill=rgba("ead49a", 120), width=3)
    mask = im.getchannel("A")
    noise_overlay(im, mask, seed + 10, 12)
    save_trimmed(im, ROOT / "paper" / asset_id / f"{variant}.png")


def make_decal(asset_id: str, variant: str, seed: int, color: str, count: int = 18) -> None:
    rng = random.Random(seed)
    im = Image.new("RGBA", (768, 384), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for _ in range(count):
        x = rng.randint(50, 700)
        y = rng.randint(50, 330)
        w = rng.randint(40, 160)
        h = rng.randint(2, 12)
        d.rectangle((x, y, x + w, y + h), fill=rgba(color, rng.randint(28, 95)))
    im = im.filter(ImageFilter.GaussianBlur(1.0))
    save_trimmed(im, ROOT / "decals" / asset_id / f"{variant}.png")


def make_prop_card(asset_id: str, variant: str, seed: int, kind: str) -> None:
    rng = random.Random(seed)
    im = Image.new("RGBA", (640, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if kind == "fence":
        d.rectangle((80, 112, 560, 350), fill=rgba("445257", 45), outline=rgba("9aa4a4", 190), width=6)
        for x in range(90, 560, 32):
            d.line((x, 116, x + 180, 350), fill=rgba("aab3ae", 120), width=3)
            d.line((x + 180, 116, x, 350), fill=rgba("68716f", 100), width=3)
    elif kind == "radio":
        d.rounded_rectangle((190, 210, 450, 350), radius=18, fill=rgba("232b2f", 245), outline=rgba("0b0e10", 240), width=5)
        d.line((390, 210, 480, 120), fill=rgba("111719", 230), width=6)
        for x in [225, 270, 315]:
            d.ellipse((x, 245, x + 34, 279), fill=rgba("637078", 190))
        for i in range(5):
            d.line((225, 306 + i * 7, 410, 306 + i * 7), fill=rgba("71808a", 130), width=3)
    elif kind == "seal":
        d.rounded_rectangle((150, 170, 500, 320), radius=16, fill=rgba("d8c06f", 235), outline=rgba("16130c", 235), width=5)
        d.rectangle((190, 205, 460, 238), fill=rgba("2f3940", 155))
        d.line((200, 270, 445, 268), fill=rgba("694328", 120), width=9)
    elif kind == "phone_bag":
        d.rounded_rectangle((150, 90, 490, 420), radius=12, fill=rgba("d7d9c9", 78), outline=rgba("e5e8da", 160), width=5)
        d.rounded_rectangle((220, 180, 410, 340), radius=22, fill=rgba("12171a", 230), outline=rgba("060708", 240), width=5)
        d.line((245, 220, 388, 305), fill=rgba("d9e8f4", 160), width=3)
    else:
        d.rounded_rectangle((165, 150, 475, 330), radius=20, fill=rgba("39484c", 230), outline=rgba("111617", 240), width=5)
    mask = im.getchannel("A")
    noise_overlay(im, mask, seed + 33, 10)
    save_trimmed(im, ROOT / "props" / asset_id / f"{asset_id}_{variant}.png")


def main() -> int:
    for asset, variants in {
        "receipt_slip": ["clean", "soaked", "torn", "carbon_copy"],
        "pawn_ticket": ["blank", "stamped", "annotated"],
        "shipping_manifest": ["clipboard", "loose_sheet", "pinned_sheet"],
        "donation_ledger_sheet": ["table_page", "highlighted_lines"],
        "audit_worksheet": ["two_column", "flagged_rows"],
        "legal_bill_stack": ["folded_envelopes", "paid_stamp_bundle"],
        "evidence_folder": ["manila", "black_binder", "clipped_packet"],
    }.items():
        for i, variant in enumerate(variants):
            make_paper(asset, variant, hash((asset, variant)) & 0xFFFF, lines=8, stamp=("stamp" in variant or "annotated" in variant or "paid" in variant))

    for asset, variants in {
        "ledger_book": ["closed", "open", "water_stained", "clipped_pages"],
        "pocket_watch": ["closed", "open_engraved_back"],
    }.items():
        for i, variant in enumerate(variants):
            make_book(asset, variant, hash((asset, variant)) & 0xFFFF, open_book=("open" in variant or "clipped" in variant))

    for asset, color in {
        "drag_scuff_wetness_decal": "617175",
        "puddle_reflection_pack": "6a929e",
        "rust_runoff_pack": "8b4a25",
        "container_serial_grime_decals": "a2a08e",
        "rain_streak_overlay": "b5c7ce",
        "oil_slick_pack": "516a70",
        "low_wall_spatter_decal": "5b0907",
    }.items():
        for variant in ["a", "b", "c"]:
            make_decal(asset, variant, hash((asset, variant)) & 0xFFFF, color)

    for asset, kind, variants in [
        ("chain_link_fence_section", "fence", ["full_panel", "gate", "broken_edge"]),
        ("police_radio_crate", "radio", ["default"]),
        ("calloway_cargo_seal", "seal", ["crate_label"]),
        ("evidence_bag", "phone_bag", ["phone", "watch", "receipt"]),
        ("vellmouth_pd_case_board", "paper", ["default"]),
        ("union_notice_cluster", "paper", ["default"]),
        ("dock_drain_runoff", "default", ["default"]),
        ("cable_chain_scatter", "default", ["default"]),
        ("brass_rubber_stamp", "default", ["default"]),
        ("security_earpiece", "default", ["default"]),
        ("police_notebook", "paper", ["default"]),
        ("dana_audit_pen", "default", ["default"]),
        ("umbrella_silhouette", "default", ["default"]),
        ("coffee_cup", "default", ["default"]),
    ]:
        for variant in variants:
            make_prop_card(asset, variant, hash((asset, variant)) & 0xFFFF, kind)

    print("generated reusable paper, decal, and simple prop packs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
