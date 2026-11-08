#!/system/bin/sh

# Tunggu sampai HP selesai booting sepenuhnya
until [ "$(getprop sys.boot_completed)" -eq 1 ]; do
  sleep 3
done

# --- OPTIMASI HARDWARE COMPOSER (HWC) ---
# Di-loop sebentar karena saat boot_completed, PID HWC terkadang belum langsung terbaca
HWC_PID=""
for i in {1..10}; do
  HWC_PID=$(pgrep -f "android.hardware.graphics.composer" | head -n 1)
  if [ -n "$HWC_PID" ]; then
    renice -n -20 -p $HWC_PID
    ionice -c 1 -n 0 -p $HWC_PID
    break
  fi
  sleep 2
done

