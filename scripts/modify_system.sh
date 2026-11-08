#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?Usage: modify_system.sh SYSTEM_ROOT [PROP_CONFIG]}"
CONFIG="${2:-config/system.prop}"

if [[ ! -d "$ROOT" ]]; then
    echo "ERROR: system-root directory not found"
    exit 1
fi

if [[ -f "$ROOT/build.prop" ]]; then
    PROP="$ROOT/build.prop"
elif [[ -f "$ROOT/system/build.prop" ]]; then
    PROP="$ROOT/system/build.prop"
else
    echo "ERROR: Main build.prop not found"
    exit 1
fi

echo "SYSTEM ROOT : $ROOT"
echo "BUILD PROP  : $PROP"
echo "CONFIG      : $CONFIG"

if [[ ! -f "$CONFIG" ]]; then
    echo "No property config found; skipping."
    exit 0
fi

python3 - "$PROP" "$CONFIG" <<'PY'
import re
import sys
from pathlib import Path

prop_file = Path(sys.argv[1])
config_file = Path(sys.argv[2])

updates = {}

for number, raw in enumerate(
    config_file.read_text(encoding="utf-8").splitlines(), 1
):
    line = raw.strip()

    if not line or line.startswith("#"):
        continue

    if "=" not in line:
        raise SystemExit(f"Invalid config line {number}: missing '='")

    key, value = line.split("=", 1)
    key = key.strip()

    if not re.fullmatch(r"[A-Za-z0-9_.-]+", key):
        raise SystemExit(f"Invalid property key at line {number}: {key}")

    if "\n" in value or "\r" in value:
        raise SystemExit(f"Invalid newline in property value at line {number}")

    updates[key] = value

if not updates:
    print("No properties requested. build.prop unchanged.")
    raise SystemExit(0)

original = prop_file.read_text(encoding="utf-8", errors="strict")
lines = original.splitlines(keepends=True)

result = []
for line in lines:
    stripped = line.rstrip("\r\n")

    if "=" in stripped and not stripped.lstrip().startswith("#"):
        existing_key = stripped.split("=", 1)[0].strip()
        if existing_key in updates:
            continue

    result.append(line)

newline = "\r\n" if "\r\n" in original else "\n"
output = "".join(result)

if output and not output.endswith(("\n", "\r")):
    output += newline

for key, value in updates.items():
    output += f"{key}={value}{newline}"

# Write to the existing inode, preserving its existing filesystem metadata.
with prop_file.open("w", encoding="utf-8", newline="") as handle:
    handle.write(output)

print(f"Applied {len(updates)} property/properties:")
for key in updates:
    print(f"  {key}")
PY

echo "System modification script completed."
