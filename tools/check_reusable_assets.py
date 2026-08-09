from pathlib import Path
import re
import sys


REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "art" / "reusable" / "props" / "MESHY_PROP_RENDER_MANIFEST.md"
REUSABLE_ROOT = REPO / "art" / "reusable"


def main() -> int:
    failures: list[str] = []

    if not MANIFEST.exists():
        failures.append(f"missing manifest: {MANIFEST}")
    else:
        text = MANIFEST.read_text(encoding="utf-8")
        paths = sorted(set(re.findall(r"`(art/reusable/[^`]+)`", text)))
        for rel in paths:
            path = REPO / rel
            if not path.exists():
                failures.append(f"manifest references missing file: {rel}")

    for path in REUSABLE_ROOT.rglob("*"):
        if not path.is_file():
            continue
        if path.name.endswith(".import"):
            continue
        name = path.name.lower()
        if "contact_sheet" in name and path.name != "meshy_prop_contact_sheet.png" and path.name != "meshy_prop_contact_sheet_trimmed.png":
            failures.append(f"unapproved contact sheet in reusable art: {path.relative_to(REPO)}")
        if "generated_asset" in name:
            failures.append(f"unapproved generated QA artifact in reusable art: {path.relative_to(REPO)}")

    if failures:
        print("FAIL reusable asset checks")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("PASS reusable asset checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
