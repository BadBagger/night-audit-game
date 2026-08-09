from __future__ import annotations

import argparse
from pathlib import Path
import sys

from PIL import Image


def alpha_profile(path: Path, threshold: int) -> tuple[list[int], tuple[int, int, int, int]]:
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda p: 255 if p >= threshold else 0).getbbox()
    if bbox is None:
        raise ValueError("alpha mask is empty")

    left, top, right, bottom = bbox
    width = right - left
    height = bottom - top

    # The body tarp should be a long horizontal silhouette. If the asset is
    # vertical, rotate the sampled mask conceptually by sampling rows instead.
    if height > width:
        profile: list[int] = []
        for y in range(top, bottom):
            xs = [x for x in range(left, right) if alpha.getpixel((x, y)) >= threshold]
            profile.append((max(xs) - min(xs) + 1) if xs else 0)
    else:
        profile = []
        for x in range(left, right):
            ys = [y for y in range(top, bottom) if alpha.getpixel((x, y)) >= threshold]
            profile.append((max(ys) - min(ys) + 1) if ys else 0)

    return smooth(profile, 19), bbox


def smooth(values: list[int], radius: int) -> list[int]:
    if not values:
        return []
    out: list[int] = []
    for i in range(len(values)):
        start = max(0, i - radius)
        end = min(len(values), i + radius + 1)
        out.append(round(sum(values[start:end]) / (end - start)))
    return out


def count_local_maxima(values: list[int], min_prominence_ratio: float) -> int:
    if len(values) < 5:
        return 0
    max_value = max(values)
    if max_value <= 0:
        return 0
    min_prominence = max_value * min_prominence_ratio
    peaks = 0
    for i in range(2, len(values) - 2):
        value = values[i]
        if value <= values[i - 1] or value < values[i + 1]:
            continue
        left_min = min(values[max(0, i - 40):i + 1])
        right_min = min(values[i:min(len(values), i + 41)])
        if value - max(left_min, right_min) >= min_prominence:
            peaks += 1
    return peaks


def edge_taper_ok(values: list[int]) -> bool:
    if len(values) < 20:
        return False
    max_value = max(values)
    if max_value <= 0:
        return False
    span = len(values)
    left_edge = max(values[: max(3, span // 12)])
    right_edge = max(values[-max(3, span // 12):])
    middle = max(values[span // 4: span * 3 // 4])
    return left_edge < middle * 0.72 and right_edge < middle * 0.72


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("--threshold", type=int, default=32)
    parser.add_argument("--min-peaks", type=int, default=3)
    args = parser.parse_args()

    profile, bbox = alpha_profile(args.image, args.threshold)
    peaks = count_local_maxima(profile, 0.07)
    taper = edge_taper_ok(profile)

    print(f"bbox={bbox}")
    print(f"profile_samples={len(profile)}")
    print(f"local_maxima={peaks}")
    print(f"edge_taper={taper}")

    if peaks < args.min_peaks:
        print(f"FAIL expected at least {args.min_peaks} body-profile maxima")
        return 1
    if not taper:
        print("FAIL expected taper at both long-axis ends")
        return 1
    print("PASS body tarp silhouette gate")
    return 0


if __name__ == "__main__":
    sys.exit(main())
