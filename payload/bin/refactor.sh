#!/system/bin/sh
# XSANZZ OS - A03 Core conservative memory profile
# Never reset/reformat zRAM after Android has activated swap.
LOG_FILE="/data/adb/xsanzz-tuning.log"
log_msg() { echo "$(date '+%F %T' 2>/dev/null) [memory] $1" >> "$LOG_FILE"; }
count=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$count" -lt 90 ]; do
  sleep 2
  count=$((count + 1))
done
if [ "$(getprop sys.boot_completed)" != "1" ]; then
  log_msg "Boot completion timeout; memory settings unchanged."
  exit 0
fi
# The stock A03 audit recorded swappiness=170, 1 GiB zRAM and LZ4.
# Only align swappiness; keep init/vendor in charge of zRAM lifecycle.
SWAPPINESS="/proc/sys/vm/swappiness"
if [ -r "$SWAPPINESS" ] && [ -w "$SWAPPINESS" ]; then
  current="$(cat "$SWAPPINESS" 2>/dev/null)"
  if [ "$current" != "170" ]; then
    if echo 170 > "$SWAPPINESS" 2>/dev/null; then
      log_msg "Swappiness changed from $current to 170."
    else
      log_msg "Could not change swappiness; current=$current."
    fi
  else
    log_msg "Swappiness already matches stock audit (170)."
  fi
else
  log_msg "Swappiness node unavailable; left unchanged."
fi
if [ -r /sys/block/zram0/disksize ]; then
  log_msg "Existing zRAM size: $(cat /sys/block/zram0/disksize) bytes."
fi
if [ -r /sys/block/zram0/comp_algorithm ]; then
  log_msg "Existing zRAM algorithms: $(cat /sys/block/zram0/comp_algorithm)."
fi
# No swapoff/reset, thermal/JEITA changes, CPU/GPU forcing, or block-queue overrides.
exit 0
