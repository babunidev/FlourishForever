#!/usr/bin/env python3
"""Read-only validation of a locally generated BigWigs packager dry-run ZIP.

Run: python3 tests/check_packaged_zip.py
Requires a prior dry run: BigWigsMods/packager release.sh -d -g 1.60.1
This does NOT verify CurseForge's private webhook or publishing settings.
"""
from pathlib import Path
import re
import sys
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "FlourishForever.toc",
    "FlourishForever.lua",
    "FlourishForever_Storage.lua",
    "FlourishForever_ActionEmotes.lua",
    "CHANGELOG.md",
    "LICENSE",
}


def main():
    candidates = sorted((ROOT / ".release").glob("*.zip"))
    if len(candidates) != 1:
        print(f"FAIL: expected one generated ZIP, found {len(candidates)}", file=sys.stderr)
        return 1

    path = candidates[0]
    with ZipFile(path) as zf:
        names = [n for n in zf.namelist() if not n.endswith("/")]
        if len(names) != len(set(names)):
            print("FAIL: duplicate names in ZIP", file=sys.stderr)
            return 1
        parts = [name.split("/", 1) for name in names]
        if any(len(item) != 2 or item[0] != "FlourishForever" for item in parts):
            print("FAIL: unexpected ZIP top-level layout", names, file=sys.stderr)
            return 1
        files = {item[1] for item in parts}
        if files != EXPECTED:
            print("FAIL: wrong ZIP contents", sorted(files), file=sys.stderr)
            print("Missing", sorted(EXPECTED - files), "Extra", sorted(files - EXPECTED), file=sys.stderr)
            return 1

        toc = zf.read("FlourishForever/FlourishForever.toc").decode("utf-8")
        if not re.search(r"^## Interface: 16001\s*$", toc, re.M):
            print("FAIL: wrong target interface", file=sys.stderr)
            return 1
        if not re.search(r"^## Version: 0\.3\.2-beta-dev\s*$", toc, re.M):
            print("FAIL: wrong addon version", file=sys.stderr)
            return 1
        changelog = zf.read("FlourishForever/CHANGELOG.md").decode("utf-8")
        if "## 0.3.2-beta" not in changelog:
            print("FAIL: missing release-notes section", file=sys.stderr)
            return 1
        license_text = zf.read("FlourishForever/LICENSE").decode("utf-8")
        if "MIT License" not in license_text:
            print("FAIL: missing MIT license text", file=sys.stderr)
            return 1

    print("PASS: packager dry-run ZIP has six intended files, correct TOC and license")
    print(f"Checked: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
