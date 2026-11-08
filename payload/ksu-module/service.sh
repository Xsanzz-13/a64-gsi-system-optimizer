#!/system/bin/sh
MODDIR="${0%/*}"
LOG_FILE="/data/adb/xsanzz-tuning.log"
(
  count=0
  while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$count" -lt 120 ]; do
    sleep 2
    count=$((count + 1))
  done
  if [ "$(getprop sys.boot_completed)" != "1" ]; then
    echo "$(date '+%F %T' 2>/dev/null) [module] boot timeout; skipped." >> "$LOG_FILE"
    exit 0
  fi
  sleep 15
  sh "$MODDIR/scripts/refactor.sh"
  sh "$MODDIR/scripts/auto.sh"
) >> "$LOG_FILE" 2>&1 &
exit 0
