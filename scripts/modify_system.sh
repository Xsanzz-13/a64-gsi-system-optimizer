#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:?Usage: modify_system.sh SYSTEM_ROOT [CONFIG_DIR_OR_FILE]}"
CONFIG_ARG="${2:-$(cd "$(dirname "$0")/.." && pwd)/config}"
if [[ ! -d "$ROOT" ]]; then
  echo "ERROR: system-root directory not found: $ROOT"
  exit 1
fi
if [[ -f "$CONFIG_ARG" ]]; then CONFIG_DIR="$(dirname "$CONFIG_ARG")"; else CONFIG_DIR="$CONFIG_ARG"; fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/apply_stock_profile.py" "$ROOT" "$CONFIG_DIR"
echo "System modification script completed."
