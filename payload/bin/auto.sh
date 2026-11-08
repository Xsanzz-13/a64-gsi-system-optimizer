#!/system/bin/sh
# XSANZZ OS - conservative HWC startup adjustment
LOG_FILE="/data/adb/xsanzz-tuning.log"
log_msg() { echo "$(date '+%F %T' 2>/dev/null) [auto] $1" >> "$LOG_FILE"; }
count=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$count" -lt 90 ]; do
  sleep 2
  count=$((count + 1))
done
if [ "$(getprop sys.boot_completed)" != "1" ]; then
  log_msg "Boot completion timeout; no HWC changes applied."
  exit 0
fi
HWC_PID=""
if command -v pgrep >/dev/null 2>&1; then
  HWC_PID="$(pgrep -f 'android.hardware.graphics.composer' 2>/dev/null | head -n 1)"
fi
case "$HWC_PID" in
  ''|*[!0-9]*) log_msg "HWC process not found; vendor scheduling policy retained."; exit 0 ;;
esac
# Mild best-effort adjustment only; no realtime policy or forced I/O priority.
if command -v renice >/dev/null 2>&1; then
  if renice -n -5 -p "$HWC_PID" >/dev/null 2>&1; then
    log_msg "HWC PID $HWC_PID niceness adjusted to -5."
  else
    log_msg "HWC PID $HWC_PID found; priority unchanged (operation unavailable)."
  fi
else
  log_msg "renice unavailable; vendor scheduling policy retained."
fi
exit 0
