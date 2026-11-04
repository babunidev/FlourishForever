#!/usr/bin/env python3
"""Static package-layout guard. Not a CurseForge packager run or in-game test.

Run from anywhere with: python3 tests/check_package_layout.py
The check intentionally fails if new tracked nonhidden files would be shipped
without a deliberate review of .pkgmeta or the TOC.
"""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "FlourishForever.toc"
PKGMETA = ROOT / ".pkgmeta"


def read_ignores():
    rules = []
    active = False
    for raw in PKGMETA.read_text(encoding="utf-8").splitlines():
        if raw.strip() == "ignore:" and not raw.startswith(" "):
            active = True
            continue
        if active and raw.strip() and not raw.startswith((" ", "#")):
            break
        if active and raw.lstrip().startswith("- "):
            rules.append(raw.strip()[2:].split("#", 1)[0].strip())
    return rules


def excluded(path, rules):
    # CurseForge ignores period-prefixed files and directories by default.
    if any(part.startswith(".") for part in Path(path).parts):
        return True
    return any(path == rule or path.startswith(rule.rstrip("/") + "/") for rule in rules)


def main():
    toc_files = {
        line.strip()
        for line in TOC.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    expected = {"FlourishForever.toc", "CHANGELOG.md"} | toc_files
    if (ROOT / "LICENSE").is_file():
        expected.add("LICENSE")

    rules = read_ignores()
    needed = {"assets", "docs", "tests", "AGENTS.md", "CONCEPT.md", "README.md", "ROADMAP.md"}
    if not needed.issubset(set(rules)):
        print("FAIL: packaging ignore rules are incomplete", file=sys.stderr)
        return 1

    proc = subprocess.run(
        ["git", "ls-files", "-z"], cwd=ROOT, check=True, capture_output=True
    )
    tracked = {p for p in proc.stdout.decode("utf-8").split("\0") if p}
    included = {p for p in tracked if not excluded(p, rules)}
    absent = sorted(expected - included)
    unexpected = sorted(included - expected)
    print("Static installable file inventory:")
    for path in sorted(included):
        print("  " + path)
    if absent or unexpected:
        print("FAIL: missing:", absent, "unexpected:", unexpected, file=sys.stderr)
        return 1

    print("PASS: source inventory matches intended CurseForge package inputs.")
    print("Note: verify the real packaged ZIP separately before any release.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
