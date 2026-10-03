"""Count repository-owned MoonBit source with a conservative line policy."""

from __future__ import annotations

import argparse
from pathlib import Path


def source_files(root: Path) -> list[Path]:
    return sorted(
        path
        for path in root.rglob("*.mbt")
        if not any(part in {"_build", "target", ".git", ".mooncakes"} for part in path.parts)
    )


def count_file(path: Path) -> tuple[int, int]:
    lines = path.read_text(encoding="utf-8").splitlines()
    effective = sum(
        1 for line in lines if line.strip() and not line.lstrip().startswith("//")
    )
    return len(lines), effective


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--minimum", type=int, default=0)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    files = source_files(args.root)
    raw = 0
    effective = 0
    for path in files:
        file_raw, file_effective = count_file(path)
        raw += file_raw
        effective += file_effective
    print(f"MoonBit files: {len(files)}")
    print(f"Raw MoonBit lines: {raw}")
    print(f"Effective MoonBit lines: {effective}")
    if effective < args.minimum:
        print(f"ERROR: effective line count is below required minimum {args.minimum}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
