#!/system/bin/sh
# Skrip zRAM (Khusus RAM 2GB)

#!/system/bin/sh

# 1. Tunggu boot
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 10
done

# 2 & 3. Reset zRAM 
swapoff /dev/block/zram0

echo 1 > /sys/block/zram0/reset

echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null

# Daftar ukuran zRAM (bytes)

# 128MB  = 134217728
# 256MB  = 268435456
# 512MB  = 536870912
# 768MB  = 805306368 
# 1GB       = 1073741824
# 1.5GB    = 1610612736
# 1.8GB    = 1932735283
# 2GGB    = 2147483648
# 2.5GB    = 2684354560
# 4GB       = 4294967296

echo 1073741824 > /sys/block/zram0/disksize

mkswap /dev/block/zram0
swapon /dev/block/zram0

# 4. Terapkan Tweaks VM & Pendukung ZRAM
echo 170 > /proc/sys/vm/swappiness
echo 20 > /proc/sys/vm/dirty_ratio
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 100 > /proc/sys/vm/vfs_cache_pressure
echo "75" > /sys/module/vmpressure/parameters/allocstall_threshold
echo "65" > /sys/module/zram/parameters/zram_balance_ratio
echo 80 > /sys/kernel/mm/vmscan/direct_swappiness

# PLUS+
setprop persist.vendor.eng.jeita 0
setprop persist.sys.thermal.ipa 0
setprop persist.sys.ss.scroll true
setprop persist.sys.pq.enabled 0
setprop debug.hwui.renderer skiaglthreaded
setprop debug.renderengine.backend skiaglthreaded

for policy in /sys/devices/system/cpu/cpufreq/policy0 /sys/devices/system/cpu/cpufreq/policy4; do
    if [ -d "$policy" ]; then
        echo schedXsn > "$policy/scaling_governor" 2>/dev/null
    fi
done

for block in /sys/block/mmcblk0 /sys/block/dm-*; do
    if [ -d "$block/queue" ]; then
        echo 0 > "$block/queue/iostats" 2>/dev/null
        echo 128 > "$block/queue/nr_requests" 2>/dev/null
        echo 2 > "$block/queue/rq_affinity" 2>/dev/null
    fi
done

PARAM_DIR="/sys/module/process_reclaim/parameters"

for param in \
    "enable_process_reclaim:1" \
    "min_score_adj:500" \
    "per_swap_size:1024" \
    "pressure_max:100" \
    "pressure_min:50" \
    "swap_eff_win:2" \
    "swap_high_ratio:100" \
    "swap_low_ratio:50" \
    "swap_opt_eff:55"
do
    name="${param%%:*}"
    value="${param#*:}"
    file="$PARAM_DIR/$name"

    if [ -f "$file" ] && [ -w "$file" ]; then
        printf '%s\n' "$value" > "$file" 2>/dev/null
    fi
done
