#!/usr/bin/env python3
"""Pack a CurseForge-shaped test ZIP from the working tree.

The ZIP contains only what a CurseForge download of this addon is meant to
contain: the TOC, the Lua files it lists, CHANGELOG.md and LICENSE.
Docs, tests, git metadata and portfolio files stay out.

Uses files as they are on disk, including uncommitted edits. This does not
upload anywhere and does not prove a CurseForge release.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import tempfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
ADDON_DIR_NAME = "FlourishForever"
# Local Forever client. `--install` with no path updates this AddOns folder.
DEFAULT_ADDONS_DIR = Path(
    "/home/babuni/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft"
) / "_forever_" / "Interface" / "AddOns"


def toc_payload(toc_text: str) -> list[str]:
    files = []
    for line in toc_text.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            files.append(stripped)
    return files


def version_label(toc_text: str) -> str:
    match = re.search(r"^## Version:\s*(\S+)\s*$", toc_text, re.M)
    if not match:
        return "unknown"
    return re.sub(r"[^A-Za-z0-9._-]+", "-", match.group(1))


def collect() -> tuple[list[str], str]:
    toc_path = ROOT / "FlourishForever.toc"
    if not toc_path.is_file():
        raise SystemExit(f"FAIL: missing {toc_path}")
    toc_text = toc_path.read_text(encoding="utf-8")
    names = [
        "FlourishForever.toc",
        *toc_payload(toc_text),
        "CHANGELOG.md",
        "LICENSE",
        "Textures/FlourishForeverLogo.tga",
    ]
    missing = [name for name in names if not (ROOT / name).is_file()]
    if missing:
        raise SystemExit("FAIL: missing package files: " + ", ".join(missing))
    if len(names) != len(set(names)):
        raise SystemExit("FAIL: duplicate package names")
    if not re.search(r"^## Interface: 16001\s*$", toc_text, re.M):
        raise SystemExit("FAIL: TOC interface is not 16001")
    return names, version_label(toc_text)


def build(names: list[str], dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        dest.unlink()
    with ZipFile(dest, "w", compression=ZIP_DEFLATED) as zf:
        for name in names:
            data = (ROOT / name).read_bytes()
            if data.startswith(b"\xef\xbb\xbf"):
                raise SystemExit(f"FAIL: {name} has a UTF-8 BOM")
            zf.writestr(f"{ADDON_DIR_NAME}/{name}", data)


def install(zip_path: Path, addons_dir: Path) -> Path:
    target = addons_dir / ADDON_DIR_NAME
    if (target / ".git").exists():
        raise SystemExit(f"FAIL: {target} is a git checkout. Refusing to replace it.")
    if not addons_dir.is_dir():
        raise SystemExit(f"FAIL: AddOns directory does not exist: {addons_dir}")
    if target.exists():
        shutil.rmtree(target)
    with tempfile.TemporaryDirectory() as tmp:
        with ZipFile(zip_path) as zf:
            names = zf.namelist()
            if any(not name.startswith(f"{ADDON_DIR_NAME}/") or name.startswith("/") for name in names):
                raise SystemExit("FAIL: ZIP layout is not a single FlourishForever folder")
            zf.extractall(tmp)
        extracted = Path(tmp) / ADDON_DIR_NAME
        shutil.move(str(extracted), str(target))
    return target


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--install",
        nargs="?",
        const=DEFAULT_ADDONS_DIR,
        default=None,
        metavar="ADDONS_DIR",
        help="Extract the ZIP into an Interface/AddOns directory. "
        "With no path, installs into the local Forever AddOns folder.",
    )
    args = parser.parse_args()
    names, version = collect()
    dest = ROOT / "dist" / f"FlourishForever-{version}-test.zip"
    build(names, dest)
    with ZipFile(dest) as zf:
        packed = [name for name in zf.namelist() if not name.endswith("/")]
    expected = {f"{ADDON_DIR_NAME}/{name}" for name in names}
    if set(packed) != expected:
        print("FAIL: ZIP contents do not match the package list", file=sys.stderr)
        return 1
    print(f"Wrote {dest}")
    print("Package files:")
    for name in sorted(packed):
        print(f"  {name}")
    if args.install:
        installed = install(dest, Path(args.install))
        print(f"Installed into {installed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
