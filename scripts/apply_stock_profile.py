#!/usr/bin/env python3
"""Apply the audited A03 Core profile to an extracted Android GSI system root."""
from __future__ import annotations
import re
import sys
from pathlib import Path


def read_updates(path: Path) -> dict[str, str]:
    updates: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise SystemExit(f"{path}:{number}: expected KEY=VALUE")
        key, value = line.split("=", 1)
        key = key.strip()
        if not re.fullmatch(r"[A-Za-z0-9_.-]+", key):
            raise SystemExit(f"{path}:{number}: invalid property key {key!r}")
        if "\n" in value or "\r" in value:
            raise SystemExit(f"{path}:{number}: newline in property value")
        updates[key] = value.strip()
    return updates


def apply_updates(prop_path: Path, updates: dict[str, str]) -> None:
    if not prop_path.is_file():
        raise SystemExit(f"Required build.prop not found: {prop_path}")
    original = prop_path.read_text(encoding="utf-8", errors="strict")
    newline = "\r\n" if "\r\n" in original else "\n"
    kept: list[str] = []
    for line in original.splitlines(keepends=True):
        raw = line.rstrip("\r\n")
        if "=" in raw and not raw.lstrip().startswith("#"):
            key = raw.split("=", 1)[0].strip()
            if key in updates:
                continue
        kept.append(line)
    output = "".join(kept)
    if output and not output.endswith(("\n", "\r")):
        output += newline
    for key, value in updates.items():
        output += f"{key}={value}{newline}"
    # Truncate the existing inode so mode/ownership/xattrs are retained.
    with prop_path.open("w", encoding="utf-8", newline="") as handle:
        handle.write(output)
    print(f"Updated {len(updates)} properties: {prop_path}")
    for key, value in updates.items():
        print(f"  {key}={value}")


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: apply_stock_profile.py SYSTEM_ROOT CONFIG_DIR", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    config = Path(sys.argv[2]).resolve()
    if not root.is_dir():
        raise SystemExit(f"System root does not exist: {root}")
    system_prop = root / "system/build.prop"
    product_prop = root / "system/product/etc/build.prop"
    apply_updates(system_prop, read_updates(config / "system.prop"))
    apply_updates(product_prop, read_updates(config / "product.prop"))
    expected = next((v for k, v in read_updates(config / "system.prop").items()
                     if k == "ro.build.display.id"), None)
    if not expected:
        raise SystemExit("ro.build.display.id missing from system.prop")
    for path in (system_prop, product_prop):
        if f"ro.build.display.id={expected}" not in path.read_text(encoding="utf-8"):
            raise SystemExit(f"Branding validation failed in {path}")
    product_text = product_prop.read_text(encoding="utf-8")
    lineage = read_updates(config / "product.prop").get("ro.lineage.display.version")
    if not lineage or f"ro.lineage.display.version={lineage}" not in product_text:
        raise SystemExit("Lineage display branding validation failed")
    print("Stock-aligned profile and About phone branding validated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
