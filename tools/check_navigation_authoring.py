import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAV_PATH = ROOT / "art" / "navigation" / "chapter1_navigation_authoring.json"
TOOL_PATH = ROOT / "tools" / "NavigationAuthoringTool.gd"


def fail(message: str) -> None:
    raise SystemExit(f"FAIL {message}")


def main() -> None:
    if not NAV_PATH.exists():
        fail(f"missing {NAV_PATH}")
    if not TOOL_PATH.exists():
        fail(f"missing {TOOL_PATH}")

    data = json.loads(NAV_PATH.read_text(encoding="utf-8"))
    for key in ("walkable", "blocked", "occluder_foreground"):
        polygons = data.get(key)
        if not isinstance(polygons, list) or not polygons:
            fail(f"{key} must contain at least one polygon")
        for polygon in polygons:
            if not isinstance(polygon, list) or len(polygon) < 3:
                fail(f"{key} polygon must contain at least three points")
            for point in polygon:
                if (
                    not isinstance(point, list)
                    or len(point) < 2
                    or not all(isinstance(value, (int, float)) for value in point[:2])
                ):
                    fail(f"{key} polygon contains invalid point {point!r}")

    source = TOOL_PATH.read_text(encoding="utf-8")
    required_snippets = [
        "_select_nearest_point",
        "_move_selected_point",
        "_insert_point_on_nearest_edge",
        "_delete_selected_point",
        "Shift+click edge insert",
        "2 blocked/no-travel",
    ]
    for snippet in required_snippets:
        if snippet not in source:
            fail(f"tool source missing {snippet}")

    print("PASS navigation authoring checks")


if __name__ == "__main__":
    main()
